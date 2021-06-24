import Foundation
import SwiftProtobuf
import os.log
import SwiftUI

/**
 Exposes internals of PromotedAIMetricsSDK workings so that clients
 can inspect time profiles, network activity, and contents of log
 messages sent to the server.
 
 Set `xrayEnabled` on the initial `ClientConfig` to enable this
 profiling for the session. Access the `xray` property on
 `MetricsLoggerService`.
 
 Like all profiling mechanisms, `Xray` incurs performance and memory
 overhead, so use in production should be judicious. `Xray` makes
 best effort to exclude its own overhead from its reports.
 
 Profile data from `Xray` is kept only in memory on the client, and
 not sent to Promoted's servers (as of 2021Q1).
 */
@objc(PROXray)
public final class Xray: NSObject {
  
  public typealias CallStack = [String]

  /** Instrumented call to Promoted library. */
  @objc(PROXrayCall)
  public final class Call: NSObject {
    
    /// Call stack that triggered logging.
    @objc public fileprivate(set) var callStack: CallStack = []
    
    /// Start time for logging execution.
    @objc public fileprivate(set) var startTime: TimeInterval = 0

    /// End time for logging execution.
    @objc public fileprivate(set) var endTime: TimeInterval = 0
    
    /// Context that produced the logging.
    @objc public fileprivate(set) var context: String = ""
    
    /// Time spent in Promoted code for this logging call.
    @objc public var timeSpent: TimeInterval { endTime - startTime }

    /// Messages that were logged, if any.
    public fileprivate(set) var messages: [Message] = []

    /// JSON representation of any messages that were logged.
    @objc public var messagesJSON: [String] {
      messages.compactMap { try? $0.jsonString() }
    }

    /// Serialized bytes of any messages that were logged.
    @objc public var messagesBytes: [Data] {
      messages.compactMap { try? $0.serializedData() }
    }

    /// Total number of serialized bytes across all messages.
    /// This count is an approximation of actual network traffic.
    @objc public var messagesSizeBytes: UInt64 {
      UInt64(messagesBytes.map(\.count).reduce(0, +))
    }

    /// Errors that resulted from this logging call.
    @objc public fileprivate(set) var error: Error? = nil
  }

  /** Batched logging call. */
  @objc(PROXrayNetworkBatch)
  public final class NetworkBatch: NSObject {

    @objc public fileprivate(set) var batchNumber: Int = 0
    
    /// Start time for batch flush.
    @objc public fileprivate(set) var startTime: TimeInterval = 0

    /// End time for batch flush. Includes time for proto serialization,
    /// but not the network latency.
    @objc public fileprivate(set) var endTime: TimeInterval = 0
    
    /// Time spent in Promoted code for batch flush.
    @objc public var timeSpent: TimeInterval { endTime - startTime }

    /// Time spent in Promoted code for batch flush and all calls
    /// contained therein.
    /// When `xrayLevel` is `.batchSummaries`, this does not
    /// include time spent in individual calls.
    @objc public var timeSpentAcrossCalls: TimeInterval {
      timeSpent + calls.map(\.timeSpent).reduce(0, +)
    }

    /// Time at which network response received.
    /// This time is asynchronous.
    @objc public fileprivate(set) var networkEndTime: TimeInterval = 0
    
    /// Message sent across the network.
    public fileprivate(set) var message: Message? = nil

    /// JSON representation of `message`.
    @objc public var messageJSON: String? { try? message?.jsonString() }

    /// Serialized bytes for `message` sent across the network.
    @objc public var messageBytes: Data? { try? message?.serializedData() }

    /// Number of serialized bytes sent across network.
    /// This count is an approximation of actual network traffic.
    /// Network traffic also includes HTTP headers, which are not
    /// counted in this size.
    @objc public fileprivate(set) var messageSizeBytes: UInt64 = 0

    /// Logging calls included in this batch.
    @objc public fileprivate(set) var calls: [Call] = []

    /// Errors that resulted from this batch.
    @objc public fileprivate(set) var errors: [Error] = []

    /// Errors that arose from this batch and across all calls
    /// contained therein.
    @objc public var errorsAcrossCalls: [Error] {
      calls.compactMap(\.error) + errors
    }
  }
  
  public static let networkBatchWindowMaxSize: Int = 100
  
  public static var timingMayBeInaccurate: Bool {
    #if DEBUG || targetEnvironment(simulator)
      return true
    #else
      return false
    #endif
  }
  
  /// Number of network batches to keep in memory.
  @objc public var networkBatchWindowSize: Int {
    didSet {
      let max = Self.networkBatchWindowMaxSize
      networkBatchWindowSize = min(networkBatchWindowSize, max)
      trimNetworkBatches()
    }
  }

  /// Total serialized bytes sent across network.
  /// This count is an approximation of actual network traffic.
  /// Network traffic also include HTTP headers, which are not
  /// counted in this size.
  @objc public private(set) var totalBytesSent: UInt64

  /// Total time spent in Promoted logging code.
  /// When `xrayLevel` is `.batchSummaries`, this does not
  /// include time spent in individual calls.
  @objc public private(set) var totalTimeSpent: TimeInterval

  /// Total number of errors encountered at any time during
  /// Promoted logging.
  @objc public private(set) var totalErrors: Int

  /// Total number of requests attempted.
  @objc public private(set) var batchesAttempted: Int

  /// Total number of requests sent across network.
  @objc public private(set) var batchesSentSuccessfully: Int

  /// Total number of batches that had errors.
  @objc public private(set) var batchesWithErrors: Int

  var currentBatchNumber: Int { batchesAttempted + 1 }

  /// Most recent network batches.
  @objc public private(set) var networkBatches: [NetworkBatch]

  /// Flattened logging calls across `networkBatches`.
  @objc public var calls: [Call] { networkBatches.flatMap(\.calls) }

  /// Flattened errors across `networkBatches`.
  @objc public var errors: [Error] {
    networkBatches.flatMap(\.errorsAcrossCalls)
  }

  private var pendingCalls: [Call]
  private var pendingBatch: NetworkBatch?
  
  private let clock: Clock
  private let xrayLevel: ClientConfig.XrayLevel
  private let osLogLevel: ClientConfig.OSLogLevel
  private let osLog: OSLog?

  typealias Deps = ClockSource & ClientConfigSource &
      OperationMonitorSource & OSLogSource

  init(deps: Deps) {
    assert(deps.clientConfig.xrayLevel != .none)

    self.clock = deps.clock
    self.xrayLevel = deps.clientConfig.xrayLevel
    self.osLogLevel = deps.clientConfig.osLogLevel
    self.osLog = deps.osLog(category: "Xray")

    self.networkBatchWindowSize = 10
    self.totalBytesSent = 0
    self.totalTimeSpent = 0
    self.totalErrors = 0
    self.batchesAttempted = 0
    self.batchesSentSuccessfully = 0
    self.batchesWithErrors = 0
    self.networkBatches = []
    self.pendingCalls = []
    self.pendingBatch = nil
    
    super.init()
    deps.operationMonitor.addOperationMonitorListener(self)
  }
}

protocol XraySource {
  var xray: Xray? { get }
}

// MARK: - Call
fileprivate extension Xray {

  private func callWillStart(context: String) {
    guard xrayLevel >= .callDetails else { return }
    let call = Call()
    call.context = context
    if xrayLevel >= .callDetailsAndStackTraces {
      // Thread.callStackSymbols is slow.
      // Make sure startTime measurement comes after this.
      call.callStack = Thread.callStackSymbols
    }
    call.startTime = clock.now
    pendingCalls.append(call)
    osLog?.signpostBegin(name: "call")
  }
  
  private func callDidLog(message: Message) {
    guard xrayLevel >= .callDetails else { return }
    osLog?.signpostEvent(name: "call", format: "log")
    guard let lastCall = pendingCalls.last else { return }
    lastCall.messages.append(message)
  }

  private func callDidError(_ error: Error) {
    totalErrors += 1
    if xrayLevel == .batchSummaries {
      // Create a call and record only the error.
      let call = Call()
      call.error = error
      pendingCalls.append(call)
      return
    }
    osLog?.signpostEvent(name: "call", format: "error: %{public}@",
                         error.localizedDescription)
    guard let lastCall = pendingCalls.last else { return }
    lastCall.error = error
  }

  private func callDidComplete() {
    guard xrayLevel >= .callDetails else { return }
    osLog?.signpostEnd(name: "call")
    guard let lastCall = pendingCalls.last else { return }
    lastCall.endTime = clock.now
  }
}

// MARK: - Batch
fileprivate extension Xray {

  private func batchWillStart() {
    if let leftoverBatch = pendingBatch {
      // Might be left over if previous batch didn't make
      // any network calls.
      add(batch: leftoverBatch)
    }
    batchesAttempted += 1
    let pendingBatch = NetworkBatch()
    pendingBatch.batchNumber = batchesAttempted
    pendingBatch.startTime = clock.now
    if xrayLevel == .batchSummaries {
      // Calls contain only errors when xrayLevel == .batchSummaries.
      // Don't record the calls as they are otherwise empty.
      pendingBatch.errors = pendingCalls.compactMap(\.error)
    } else {
      pendingBatch.calls = pendingCalls
    }
    self.pendingBatch = pendingBatch
    self.pendingCalls.removeAll()
    osLog?.signpostBegin(name: "batch")
  }

  private func batchWillSend(message: Message) {
    osLog?.signpostEvent(name: "batch", format: "sendMessage")
    osLog?.signpostBegin(name: "network")
    guard let pendingBatch = pendingBatch else { return }
    pendingBatch.message = message
  }

  private func batchWillSend(data: Data) {
    let size = data.count
    osLog?.signpostEvent(name: "batch", format: "sendURLRequest: %{public}d bytes", size)
    guard let pendingBatch = pendingBatch else { return }
    pendingBatch.messageSizeBytes = UInt64(size)
  }

  private func batchDidError(_ error: Error) {
    osLog?.signpostEvent(name: "batch", format: "error: %{public}@",
                         error.localizedDescription)
    guard let pendingBatch = pendingBatch else { return }
    pendingBatch.errors.append(error)
    totalErrors += 1
  }

  private func batchDidComplete() {
    osLog?.signpostEnd(name: "batch")
    guard let pendingBatch = pendingBatch else { return }
    pendingBatch.endTime = clock.now
    totalTimeSpent += pendingBatch.timeSpentAcrossCalls
    if !pendingBatch.errors.isEmpty {
      add(batch: pendingBatch)
      self.pendingBatch = nil
    }
  }

  private func batchResponseDidError(_ error: Error) {
    osLog?.signpostEvent(name: "network", format: "error: %{public}@",
                         error.localizedDescription)
    guard let pendingBatch = pendingBatch else { return }
    pendingBatch.networkEndTime = clock.now
    pendingBatch.errors.append(error)
    batchesWithErrors += 1
    totalErrors += 1
  }

  private func batchResponseDidComplete() {
    osLog?.signpostEnd(name: "network")
    guard let pendingBatch = pendingBatch else { return }
    pendingBatch.networkEndTime = clock.now
    totalBytesSent += pendingBatch.messageSizeBytes
    batchesSentSuccessfully += 1
    add(batch: pendingBatch)
    self.pendingBatch = nil
    logBatchResponseCompleteStats()
  }

  private func add(batch: NetworkBatch) {
    networkBatches.append(batch)
    trimNetworkBatches()
  }

  private func trimNetworkBatches() {
    let excess = networkBatches.count - networkBatchWindowSize
    if excess > 0 {
      // networkBatches.removeFirst(k) is O(networkBatches.count).
      // Not worth optimizing right now, but could use a circular
      // buffer (available in Swift 5.5!) to avoid this.
      networkBatches.removeFirst(excess)
    }
  }

  private func logBatchResponseCompleteStats() {
    guard osLogLevel >= .info, let osLog = osLog else { return }
    if Self.timingMayBeInaccurate {
      osLog.info("WARNING: Timing may be inaccurate when running in debug or simulator.")
    }
    if let batch = networkBatches.last {
      osLog.info("Latest batch: %{private}@", String(describing: batch))
      #if DEBUG
      if osLogLevel >= .debug {
        logOperationSummaryTable(batch: batch)
        logMessageSummaryTable(batch: batch)
      }
      #endif
    }
    osLog.info("Total: %{public}lld ms, %{public}lld bytes, %{public}d requests",
               totalTimeSpent.millis, totalBytesSent, batchesSentSuccessfully)
  }

  private func logOperationSummaryTable(batch: NetworkBatch) {
    guard osLogLevel >= .debug, let osLog = osLog else { return }
    let formatter = TabularLogFormatter(name:"Operations in Batch \(batch.batchNumber)")
    formatter.addField(name: "Context", width: 25, alignment: .left)
    formatter.addField(name: "Millis", width: 10, alignment: .right)
    formatter.addField(name: "Msg Count", width: 10, alignment: .right)
    formatter.addField(name: "Msg Bytes", width: 10, alignment: .right)
    formatter.addField(name: "Summary", width: 30, alignment: .left)
    for call in batch.calls {
      let summary = call.messages.map { message in
        switch message {
        case let view as Event_View:
          return "View(\(view.name), \(view.viewID.suffix(4)))"
        case let impression as Event_Impression:
          return "Imp(\(impression.impressionID.suffix(4)))"
        case let action as Event_Action:
          return "Act(\(action.name), \(action.actionID.suffix(4)))"
        default:
          return message.loggingName
        }
      }.joined(separator: ", ")
      formatter.addRow(call.context,
                       call.timeSpent.millis,
                       call.messages.count,
                       call.messagesSizeBytes,
                       summary)
    }
    osLog.debug(formatter)
  }

  private func logMessageSummaryTable(batch: NetworkBatch) {
    guard osLogLevel >= .debug, let osLog = osLog else { return }
    let formatter = TabularLogFormatter(name:"Messages in Batch \(batch.batchNumber)")
    formatter.addField(name: "Type", width: 10)
    formatter.addField(name: "Name", width: 25)
    formatter.addField(name: "LogUserID", width: 20)
    formatter.addField(name: "ViewID", width: 20)
    formatter.addField(name: "ImpressionID", width: 20)
    formatter.addField(name: "ActionID", width: 20)
    let logUserID = (batch.message as? Event_LogRequest)?.userInfo.logUserID ?? "-"
    for message in batch.calls.flatMap(\.messages) {
      let type = message.loggingName
      switch message {
      case let view as Event_View:
        formatter.addRow(type, view.name, logUserID, view.viewID, "-", "-")
      case let impression as Event_Impression:
        formatter.addRow(type, "-", logUserID, impression.viewID,
                         impression.impressionID, "-")
      case let action as Event_Action:
        formatter.addRow(type, action.name, logUserID, action.viewID,
                         action.impressionID, action.actionID)
      default:
        formatter.addRow(type, "-", "-", "-", "-", "-")
      }
    }
    osLog.debug(formatter)
  }
}

extension Message {
  var loggingName: String {
    return String(describing: type(of: self))
      .replacingOccurrences(of: "Event_", with: "")
      .replacingOccurrences(of: "Delivery_", with: "")
  }
}

extension Xray: OperationMonitorListener {
  func executionWillStart(context: Context) {
    switch context {
    case .function(let function):
      callWillStart(context: function)
    case .batch:
      batchWillStart()
    case .batchResponse:
      break  // We don't record this start, only the end.
    }
  }

  func executionDidEnd(context: Context) {
    switch context {
    case .function(_):
      callDidComplete()
    case .batch:
      batchDidComplete()
    case .batchResponse:
      batchResponseDidComplete()
    }
  }

  func execution(context: Context, didError error: Error) {
    switch context {
    case .function(_):
      callDidError(error)
    case .batch:
      batchDidError(error)
    case .batchResponse:
      batchResponseDidError(error)
    }
  }
  
  func execution(context: Context, willLogMessage message: Message) {
    switch context {
    case .function(_):
      callDidLog(message: message)
    case .batch:
      batchWillSend(message: message)
    case .batchResponse:
      break  // No messages associated with batch response.
    }
  }

  func execution(context: Context, willLogData data: Data) {
    if case .batch = context {
      batchWillSend(data: data)
    }
  }
}

extension Xray.Call {
  public override var description: String {
    return debugDescription
  }

  public override var debugDescription: String {
    let context = String(describing: self.context)
    let messageCount = messages.count
    let messageSize = messagesSizeBytes
    return "(\(context): \(timeSpent.millis) ms, \(messageCount) msgs, " +
           "\(messageSize) bytes)"
  }
}

extension Xray.NetworkBatch {
  public override var description: String {
    return debugDescription
  }

  public override var debugDescription: String {
    let callCount = calls.count
    let eventCount = calls.flatMap(\.messages).count
    let messageSize = messageSizeBytes
    return "(\(timeSpentAcrossCalls.millis) ms, \(callCount) calls, " +
           "\(eventCount) events, \(messageSize) bytes)"
  }
}

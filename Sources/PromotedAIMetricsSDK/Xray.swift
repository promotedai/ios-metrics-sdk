import Foundation
import SwiftProtobuf
import os.log

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
  }

  /** Batched logging call. */
  @objc(PROXrayNetworkBatch)
  public final class NetworkBatch: NSObject {
    
    /// Start time for batch flush.
    @objc public fileprivate(set) var startTime: TimeInterval = 0

    /// End time for batch flush. Includes time for proto serialization,
    /// but not the network latency.
    @objc public fileprivate(set) var endTime: TimeInterval = 0
    
    /// Time spent in Promoted code for batch flush.
    @objc public var timeSpent: TimeInterval { endTime - startTime }

    /// Time spent in Promoted code for batch flush and all calls
    /// contained therein.
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
    @objc public fileprivate(set) var error: Error? = nil
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

  /// Total number of requests sent across network.
  @objc public private(set) var totalRequestsMade: Int

  /// Total time spent in Promoted logging code.
  @objc public private(set) var totalTimeSpent: TimeInterval

  /// Most recent network batches.
  @objc public private(set) var networkBatches: [NetworkBatch]

  /// Flattened logging calls across `networkBatches`.
  @objc public var calls: [Call] { networkBatches.flatMap(\.calls) }

  /// Flattened errors across `networkBatches`.
  @objc public var errors: [Error] { networkBatches.compactMap(\.error) }

  private var pendingCalls: [Call]
  private var pendingBatch: NetworkBatch?
  
  private let clock: Clock
  private let callStacksEnabled: Bool
  private let osLog: OSLog?

  init(clock: Clock,
       config: ClientConfig,
       monitor: OperationMonitor,
       osLog: OSLog?) {
    self.clock = clock
    self.callStacksEnabled = config.xrayExpensiveThreadCallStacksEnabled
    self.osLog = osLog

    self.networkBatchWindowSize = 10
    self.totalBytesSent = 0
    self.totalRequestsMade = 0
    self.totalTimeSpent = 0
    self.networkBatches = []
    self.pendingCalls = []
    self.pendingBatch = nil

    super.init()
    monitor.addOperationMonitorListener(self)
  }

  // MARK: - Call
  func callWillStart(context: String) {
    let call = Call()
    call.context = context
    if callStacksEnabled {
      // Thread.callStackSymbols is slow.
      // Make sure startTime measurement comes after this.
      call.callStack = Thread.callStackSymbols
    }
    call.startTime = clock.now
    pendingCalls.append(call)
    osLog?.signpostBegin(name: "call")
  }
  
  func callDidLog(message: Message) {
    osLog?.signpostEvent(name: "call", format: "log")
    guard let lastCall = pendingCalls.last else { return }
    lastCall.messages.append(message)
  }

  func callDidComplete() {
    osLog?.signpostEnd(name: "call")
    guard let lastCall = pendingCalls.last else { return }
    lastCall.endTime = clock.now
  }
  
  // MARK: - Batch
  func metricsLoggerBatchWillStart() {
    if let leftoverBatch = pendingBatch {
      // Might be left over if previous batch didn't make
      // any network calls.
      add(batch: leftoverBatch)
    }
    let pendingBatch = NetworkBatch()
    pendingBatch.startTime = clock.now
    pendingBatch.calls = pendingCalls
    self.pendingBatch = pendingBatch
    self.pendingCalls.removeAll()
    osLog?.signpostBegin(name: "batch")
  }
  
  func metricsLoggerBatchWillSend(message: Message) {
    osLog?.signpostEvent(name: "batch", format: "sendMessage")
    guard let pendingBatch = pendingBatch else { return }
    pendingBatch.message = message
  }
  
  func metricsLoggerBatchWillSend(data: Data) {
    let size = data.count
    osLog?.signpostEvent(name: "batch", format: "sendURLRequest: %{public}d bytes", size)
    osLog?.signpostBegin(name: "network")
    guard let pendingBatch = pendingBatch else { return }
    pendingBatch.messageSizeBytes = UInt64(size)
  }
  
  func metricsLoggerBatchDidError(_ error: Error) {
    osLog?.signpostEvent(name: "batch", format: "error: %{public}@",
                         error.localizedDescription)
    guard let pendingBatch = pendingBatch else { return }
    pendingBatch.error = error
  }

  func metricsLoggerBatchDidComplete() {
    osLog?.signpostEnd(name: "batch")
    guard let pendingBatch = pendingBatch else { return }
    pendingBatch.endTime = clock.now
    totalTimeSpent += pendingBatch.timeSpentAcrossCalls
    if pendingBatch.error != nil {
      add(batch: pendingBatch)
      self.pendingBatch = nil
    }
  }
  
  func metricsLoggerBatchResponseDidError(_ error: Error) {
    osLog?.signpostEvent(name: "network", format: "error: %{public}@",
                         error.localizedDescription)
    guard let pendingBatch = pendingBatch else { return }
    pendingBatch.networkEndTime = clock.now
    pendingBatch.error = error
  }
  
  func metricsLoggerBatchResponseDidComplete() {
    osLog?.signpostEnd(name: "network")
    guard let pendingBatch = pendingBatch else { return }
    pendingBatch.networkEndTime = clock.now
    totalBytesSent += pendingBatch.messageSizeBytes
    totalRequestsMade += 1
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
      // buffer to avoid this.
      networkBatches.removeFirst(excess)
    }
  }
  
  private func logBatchResponseCompleteStats() {
    guard let osLog = osLog else { return }
    if Self.timingMayBeInaccurate {
      osLog.info("WARNING! Timing may be inaccurate when running in debug or simulator.")
    }
    if let batch = networkBatches.last {
      osLog.info("Latest batch: %{private}@", String(describing: batch))
    }
    osLog.info("Total: %{public}lld ms, %{public}lld bytes, %{public}d requests",
               totalTimeSpent.millis, totalBytesSent, totalRequestsMade)
  }
}

extension Xray: OperationMonitorListener {
  func executionWillStart(context: String) {
    callWillStart(context: context)
  }

  func executionDidEnd(context: String) {
    callDidComplete()
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
    let eventCount = calls.flatMap { $0.messages }.count
    let messageSize = messageSizeBytes
    return "(\(timeSpentAcrossCalls.millis) ms, \(callCount) calls, " +
           "\(eventCount) events, \(messageSize) bytes)"
  }
}

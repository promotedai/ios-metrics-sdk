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
public class Xray: NSObject {
  
  public typealias CallStack = [String]
  
  /** Origin or reason for activity in Promoted library. */
  @objc(PROXrayContext)
  public enum Context: Int {
    case unspecified = 0

    /// Starting session when user is decided.
    case startSession
    
    /// Direct call to `MetricsLogger`.
    case logUser

    /// Direct call to `MetricsLogger`.
    case logSession

    /// Direct call to `MetricsLogger`.
    case logImpression

    /// Direct call to `MetricsLogger`.
    case logAction

    /// Direct call to `MetricsLogger`.
    case logView

    /// Called from `ImpressionLogger.collectionViewWillDisplay(content:)`.
    /// May not trigger log messages, so `Call.messages` may be empty
    /// for this context.
    case impressionLoggerWillDisplay

    /// Called from `ImpressionLogger.collectionViewDidHide(content:)`.
    /// May not trigger log messages, so `Call.messages` may be empty
    /// for this context.
    case impressionLoggerDidHide

    /// Called from `ImpressionLogger.collectionViewDidChangeVisibleContent(:)`.
    /// May not trigger log messages, so `Call.messages` may be empty
    /// for this context.
    case impressionLoggerDidChange

    /// Called from `ImpressionLogger.collectionViewDidHideAllContent()`.
    /// May not trigger log messages, so `Call.messages` may be empty
    /// for this context.
    case impressionLoggerDidHideAll

    /// Called from one of `ScrollTracker`'s `setFrames*` methods.
    /// Will not trigger log messages, so `Call.messages` will be empty
    /// for this context.
    case scrollTrackerSetFrames

    /// Called when `ScrollTracker` sends impressions.
    /// May not trigger log messages, so `Call.messages` may be empty
    /// for this context.
    case scrollTrackerUpdate
  }

  /** Instrumented call to Promoted library. */
  @objc(PROXrayCall)
  public class Call: NSObject {
    
    /// Call stack that triggered logging.
    @objc public fileprivate(set) var callStack: CallStack = []
    
    /// Start time for logging execution.
    @objc public fileprivate(set) var startTime: TimeInterval = 0
    
    /// End time for logging execution.
    @objc public fileprivate(set) var endTime: TimeInterval = 0
    
    /// Context that produced the logging.
    @objc public fileprivate(set) var context: Context = .unspecified
    
    /// Time spent in Promoted code for this logging call.
    @objc public var timeSpent: TimeInterval { endTime - startTime }
    
    @objc public var timeSpentMillis: TimeIntervalMillis {
      TimeIntervalMillis(seconds: timeSpent)
    }

    /// Messages that were logged, if any.
    public fileprivate(set) var messages: [Message] = []

    /// JSON representation of any messages that were logged.
    @objc public var messagesJSON: [String] {
      messages.map {
        do { return try $0.jsonString() } catch { return "'ERROR'" }
      }
    }

    /// Serialized bytes of any messages that were logged.
    @objc public var messagesBytes: [Data] {
      messages.map {
        do { return try $0.serializedData() } catch { return Data() }
      }
    }

    /// Total number of serialized bytes across all messages.
    /// This count is an approximation of actual network traffic.
    @objc public var messagesSizeBytes: UInt64 {
      UInt64(messagesBytes.map(\.count).reduce(0, +))
    }
  }

  /** Batched logging call. */
  @objc(PROXrayNetworkBatch)
  public class NetworkBatch: NSObject {
    
    /// Start time for batch flush.
    @objc public fileprivate(set) var startTime: TimeInterval = 0

    /// End time for batch flush. Includes time for proto serialization,
    /// but not the network latency.
    @objc public fileprivate(set) var endTime: TimeInterval = 0

    /// Time spent in Promoted code for batch flush.
    @objc public var timeSpent: TimeInterval { endTime - startTime }
    
    @objc public var timeSpentMillis: TimeIntervalMillis {
      TimeIntervalMillis(seconds: timeSpent)
    }

    /// Time spent in Promoted code for batch flush and all calls
    /// contained therein.
    @objc public var timeSpentAcrossCalls: TimeInterval {
      timeSpent + calls.map(\.timeSpent).reduce(0, +)
    }
    
    @objc public var timeSpentAcrossCallsMillis: TimeIntervalMillis {
      TimeIntervalMillis(seconds: timeSpentAcrossCalls)
    }

    /// Time at which network response received.
    /// This time is asynchronous.
    @objc public fileprivate(set) var networkEndTime: TimeInterval = 0

    /// Message sent across the network.
    public fileprivate(set) var message: Message? = nil

    /// JSON representation of `message`.
    @objc public var messageJSON: String {
      if let json = try? message?.jsonString() {
        return json
      }
      return "'ERROR'"
    }

    /// Serialized bytes for `message` sent across the network.
    @objc public var messageBytes: Data {
      if let bytes = try? message?.serializedData() {
        return bytes
      }
      return Data()
    }

    /// Number of serialized bytes sent across network.
    /// This count is an approximation of actual network traffic.
    /// Network traffic also include HTTP headers, which are not
    /// counted in this size.
    @objc public var messageSizeBytes: UInt64 = 0

    /// Logging calls included in this batch.
    @objc public fileprivate(set) var calls: [Call] = []

    /// Errors that resulted from this batch.
    @objc public fileprivate(set) var error: Error? = nil
  }
  
  public static let networkBatchWindowMaxSize: Int = 100
  
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
  
  @objc public var totalTimeSpentMillis: TimeIntervalMillis {
    TimeIntervalMillis(seconds: totalTimeSpent)
  }

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
  private let osLog: OSLog

  init(clock: Clock, config: ClientConfig) {
    self.clock = clock
    self.callStacksEnabled = config.xrayExpensiveThreadCallStacksEnabled

    self.networkBatchWindowSize = 10
    self.totalBytesSent = 0
    self.totalRequestsMade = 0
    self.totalTimeSpent = 0
    self.networkBatches = []
    self.pendingCalls = []
    self.pendingBatch = nil
    
    if #available(iOS 12.0, *) {
      self.osLog = OSLog(subsystem: "ai.promoted.Xray", category: .pointsOfInterest)
    } else {
      self.osLog = OSLog(subsystem: "ai.promoted.Xray", category: "Xray")
    }
  }
  
  private func signpostBegin(name: StaticString) {
    if #available(iOS 12.0, *) {
      os_signpost(.begin, log: osLog, name: name)
    }
  }
  
  private func signpostEvent(name: StaticString,
                             format: StaticString = "",
                             _ arguments: CVarArg...) {
    if #available(iOS 12.0, *) {
      os_signpost(.event, log: osLog, name: name, format, arguments)
    }
  }
  
  private func signpostEnd(name: StaticString) {
    if #available(iOS 12.0, *) {
      os_signpost(.end, log: osLog, name: name)
    }
  }
  
  // MARK: - Call
  func callWillStart(context: Context) {
    let call = Call()
    call.context = context
    if callStacksEnabled {
      // Thread.callStackSymbols is slow.
      // Make sure startTime measurement comes after this.
      call.callStack = Thread.callStackSymbols
    }
    call.startTime = clock.now
    pendingCalls.append(call)
    signpostBegin(name: "call")
  }
  
  func callDidLog(message: Message) {
    signpostEvent(name: "call", format: "log")
    guard let lastCall = pendingCalls.last else { return }
    lastCall.messages.append(message)
  }

  func callDidComplete() {
    signpostEnd(name: "call")
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
    signpostBegin(name: "batch")
  }
  
  func metricsLoggerBatchWillSend(message: Message) {
    signpostEvent(name: "batch", format: "sendMessage")
    guard let pendingBatch = pendingBatch else { return }
    pendingBatch.message = message
  }
  
  func metricsLoggerBatchWillSend(urlRequest: URLRequest) {
    let size = urlRequest.httpBody?.count ?? 0
    signpostEvent(name: "batch", format: "sendURLRequest: %{public}d bytes", size)
    signpostBegin(name: "network")
    guard let pendingBatch = pendingBatch else { return }
    pendingBatch.messageSizeBytes = UInt64(size)
  }
  
  func metricsLoggerBatchDidError(_ error: Error) {
    signpostEvent(name: "batch", format: "error: %{public}s", error.localizedDescription)
    guard let pendingBatch = pendingBatch else { return }
    pendingBatch.error = error
  }

  func metricsLoggerBatchDidComplete() {
    signpostEnd(name: "batch")
    guard let pendingBatch = pendingBatch else { return }
    pendingBatch.endTime = clock.now
    totalTimeSpent += pendingBatch.timeSpentAcrossCalls
    if pendingBatch.error != nil {
      add(batch: pendingBatch)
      self.pendingBatch = nil
    }
  }
  
  func metricsLoggerBatchResponseDidError(_ error: Error) {
    signpostEvent(name: "network", format: "error: %{public}s", error.localizedDescription)
    guard let pendingBatch = pendingBatch else { return }
    pendingBatch.networkEndTime = clock.now
    pendingBatch.error = error
  }
  
  func metricsLoggerBatchResponseDidComplete() {
    signpostEnd(name: "network")
    guard let pendingBatch = pendingBatch else { return }
    pendingBatch.networkEndTime = clock.now
    totalBytesSent += pendingBatch.messageSizeBytes
    totalRequestsMade += 1
    add(batch: pendingBatch)
    self.pendingBatch = nil
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
}

extension Xray.Call {
  public override var description: String {
    return debugDescription
  }

  public override var debugDescription: String {
    let context = String(describing: self.context)
    let messageCount = messages.count
    let messageSize = messagesSizeBytes
    return "(\(context): \(timeSpentMillis) ms, \(messageCount) msgs, " +
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
    return "(\(timeSpentAcrossCallsMillis) ms, \(callCount) calls, " +
           "\(eventCount) events, \(messageSize) bytes)"
  }
}

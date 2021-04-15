import Foundation
import SwiftProtobuf

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
 not sent to Promoted's servers (as of 2021Q1). This may change in
 the future.
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
    /// May not trigger log messages, so `MetricsLoggerCall.messages`
    /// may be empty for this context.
    case impressionLoggerWillDisplay

    /// Called from `ImpressionLogger.collectionViewDidHide(content:)`.
    /// May not trigger log messages, so `MetricsLoggerCall.messages`
    /// may be empty for this context.
    case impressionLoggerDidHide

    /// Called from `ImpressionLogger.collectionViewDidChangeVisibleContent(:)`.
    /// May not trigger log messages, so `MetricsLoggerCall.messages`
    /// may be empty for this context.
    case impressionLoggerDidChange

    /// Called from `ImpressionLogger.collectionViewDidHideAllContent()`.
    /// May not trigger log messages, so `MetricsLoggerCall.messages`
    /// may be empty for this context.
    case impressionLoggerDidHideAll

    /// Called from one of `ScrollTracker`'s `setFrames*` methods.
    /// Will not trigger log messages, so `MetricsLoggerCall.messages`
    /// will be empty for this context.
    case scrollTrackerSetFrames

    /// Called when `ScrollTracker` sends impressions.
    /// May not trigger log messages, so `MetricsLoggerCall.messages`
    /// may be empty for this context.
    case scrollTrackerUpdate
  }

  /** Instrumented call to Promoted library. */
  @objc(PROXrayCall)
  public class Call: NSObject {
    
    /// Call stack that triggered logging.
    @objc public fileprivate(set) var callStack: CallStack = []
    
    /// Start time for logging execution.
    @objc public fileprivate(set) var startTime: TimeIntervalMillis = 0
    
    /// End time for logging execution.
    @objc public fileprivate(set) var endTime: TimeIntervalMillis = 0
    
    /// Context that produced the logging.
    @objc public fileprivate(set) var context: Context = .unspecified
    
    /// Time spent in Promoted code for this logging call.
    @objc public var timeSpent: TimeIntervalMillis { return endTime - startTime }

    /// Messages that were logged, if any.
    public fileprivate(set) var messages: [Message] = []

    /// JSON representation of any messages that were logged.
    @objc public var messagesJSON: [String] {
      return messages.map {
        do { return try $0.jsonString() } catch { return "'ERROR'" }
      }
    }

    /// Serialized bytes of any messages that were logged.
    @objc public var messagesBytes: [Data] {
      return messages.map {
        do { return try $0.serializedData() } catch { return Data() }
      }
    }

    /// Total number of serialized bytes across all messages.
    /// This count is an approximation of actual network traffic.
    @objc public var messagesSizeBytes: UInt64 {
      return UInt64(messagesBytes.map { $0.count }.reduce(0, +))
    }
  }

  /** Batched logging call. */
  @objc(PROXrayNetworkBatch)
  public class NetworkBatch: NSObject {
    
    /// Approximate bytes sent across network.
    @objc public fileprivate(set) var bytesSent: UInt64 = 0
    
    /// Start time for batch flush.
    @objc public fileprivate(set) var startTime: TimeIntervalMillis = 0

    /// End time for batch flush. Includes time for proto serialization,
    /// but not the network latency.
    @objc public fileprivate(set) var endTime: TimeIntervalMillis = 0

    /// Time spent in Promoted code for batch flush.
    @objc public var timeSpent: TimeIntervalMillis { return endTime - startTime }

    /// Time spent in Promoted code for batch flush and all calls
    /// contained therein.
    @objc public var timeSpentAcrossCalls: TimeIntervalMillis {
      return timeSpent + calls.map { $0.timeSpent }.reduce(0, +)
    }

    /// Time at which network response received.
    /// This time is asynchronous.
    @objc public fileprivate(set) var networkEndTime: TimeIntervalMillis = 0

    /// Message sent across the network.
    public fileprivate(set) var message: Message? = nil

    /// JSON representation of `message`.
    @objc public var messageJSON: String {
      guard let message = message else { return "" }
      do { return try message.jsonString() } catch { return "'ERROR'" }
    }

    /// Serialized bytes for `message` sent across the network.
    @objc public var messageBytes: Data {
      guard let message = message else { return Data() }
      do { return try message.serializedData() } catch { return Data() }
    }

    /// Total number of serialized bytes sent across network.
    /// This count is an approximation of actual network traffic.
    /// Network traffic also include HTTP headers, which are not
    /// counted in this size.
    @objc public var messageSizeBytes: UInt64 {
      return UInt64(messageBytes.count)
    }

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
  @objc public private(set) var totalTimeSpent: TimeIntervalMillis

  /// Most recent network batches.
  @objc public private(set) var networkBatches: [NetworkBatch]

  /// Flattened logging calls across `networkBatches`.
  @objc public var calls: [Call] {
    return networkBatches.flatMap { $0.calls }
  }

  /// Flattened errors across `networkBatches`.
  @objc public var errors: [Error] {
    return networkBatches.compactMap { $0.error }
  }

  private var pendingCalls: [Call]
  private var pendingBatch: NetworkBatch?
  
  private let clock: Clock
  private let callStacksEnabled: Bool

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
    call.startTime = clock.nowMillis
    pendingCalls.append(call)
  }
  
  func callDidLog(message: Message) {
    guard let lastCall = pendingCalls.last else { return }
    lastCall.messages.append(message)
  }

  func callDidComplete() {
    guard let lastCall = pendingCalls.last else { return }
    lastCall.endTime = clock.nowMillis
  }
  
  // MARK: - Batch
  func metricsLoggerBatchWillStart() {
    if let leftoverBatch = pendingBatch {
      // Might be left over if previous batch didn't make
      // any network calls.
      add(batch: leftoverBatch)
    }
    let pendingBatch = NetworkBatch()
    pendingBatch.startTime = clock.nowMillis
    pendingBatch.calls = pendingCalls
    self.pendingBatch = pendingBatch
    self.pendingCalls.removeAll()
  }
  
  func metricsLoggerBatchWillSend(message: Message) {
    guard let pendingBatch = pendingBatch else { return }
    pendingBatch.message = message
  }
  
  func metricsLoggerBatchDidError(_ error: Error) {
    guard let pendingBatch = pendingBatch else { return }
    pendingBatch.error = error
  }

  func metricsLoggerBatchDidComplete() {
    guard let pendingBatch = pendingBatch else { return }
    pendingBatch.endTime = clock.nowMillis
    totalTimeSpent += pendingBatch.timeSpentAcrossCalls
    if pendingBatch.error != nil {
      add(batch: pendingBatch)
      self.pendingBatch = nil
    }
  }
  
  func metricsLoggerBatchResponseDidError(_ error: Error) {
    guard let pendingBatch = pendingBatch else { return }
    pendingBatch.networkEndTime = clock.nowMillis
    pendingBatch.error = error
  }
  
  func metricsLoggerBatchResponseDidComplete() {
    guard let pendingBatch = pendingBatch else { return }
    pendingBatch.networkEndTime = clock.nowMillis
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
    return "(\(context): \(timeSpent) ms, \(messageCount) msgs, " +
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
    return "(\(timeSpent) ms, \(callCount) calls, \(eventCount) events, " +
           "\(messageSize) bytes)"
  }
}

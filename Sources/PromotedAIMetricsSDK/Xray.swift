import Foundation
import SwiftProtobuf

/**
 Exposes internals of PromotedAIMetricsSDK workings so that clients
 can inspect. Includes time profile, network activity, and contents
 of log messages sent to the server.
 
 Set `xrayEnabled` on the initial `ClientConfig` to enable this
 profiling for the session. Access the `xray` property on
 `MetricsLoggerService`.
 
 Like all profiling mechanisms, `Xray` incurs a performance and memory
 overhead, so use in production should be judicious. `Xray` makes
 best effort to exclude its own overhead from its reports.
 
 Profile data from `Xray` is kept only in memory on the client, and
 not sent to Promoted's servers (as of 2021Q1). This may change in
 the future.
 */
@objc(PROXray)
public class Xray: NSObject {
  
  public typealias CallStack = [String]
  
  /** Origin or reason for a logging call. */
  @objc(PROXrayContext)
  public enum Context: Int {
    case unspecified = 0

    /// Starting session when user is decided.
    case startSession
    
    /// Direct call to `MetricsLogger`.
    case logUser
    
    case logSession

    /// Direct call to `MetricsLogger`.
    case logImpression

    /// Direct call to `MetricsLogger`.
    case logAction

    /// Direct call to `MetricsLogger`.
    case logView

    /// Called from `ImpressionLogger.collectionViewWillDisplay(content:)`.
    /// May not trigger log messages, so the corresponding
    /// `MetricsLoggerCall.messages` for this context may be empty.
    case impressionLoggerWillDisplay

    /// Called from `ImpressionLogger.collectionViewDidHide(content:)`.
    /// May not trigger log messages, so the corresponding
    /// `MetricsLoggerCall.messages` for this context may be empty.
    case impressionLoggerDidHide

    /// Called from `ImpressionLogger.collectionViewDidChangeVisibleContent(:)`.
    /// May not trigger log messages, so the corresponding
    /// `MetricsLoggerCall.messages` for this context may be empty.
    case impressionLoggerDidChange

    /// Called from `ImpressionLogger.collectionViewDidHideAllContent()`.
    /// May not trigger log messages, so the corresponding
    /// `MetricsLoggerCall.messages` for this context may be empty.
    case impressionLoggerDidHideAll

    /// Called from one of `ScrollTracker`'s `setFrames*` methods.
    /// Will not trigger log messages, so the corresponding
    /// `MetricsLoggerCall.messages` for this context will be empty.
    case scrollTrackerSetFrames

    /// Called from `ScrollTracker`'s `scrollViewDidScroll` method.
    /// May not trigger log messages, so the corresponding
    /// `MetricsLoggerCall.messages` for this context may be empty.
    case scrollTrackerDidScroll
  }

  /** Instrumented call to perform logging. */
  @objc(PROXrayMetricsLoggerCall)
  public class MetricsLoggerCall: NSObject {
    
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
    @objc public lazy var messagesJSON: [String] = {
      return messages.map {
        do { return try $0.jsonString() } catch { return "'ERROR'" }
      }
    } ()

    /// Serialized bytes of any messages that were logged.
    @objc public lazy var messagesBytes: [Data] = {
      return messages.map {
        do { return try $0.serializedData() } catch { return Data() }
      }
    } ()

    /// Total number of serialized bytes across all messages.
    /// This count is an approximation of actual network traffic.
    @objc public lazy var messagesSizeBytes: UInt64 = {
      var result: UInt64 = 0
      messagesBytes.forEach { result += UInt64($0.count) }
      return result
    } ()
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
      return timeSpent + metricsLoggerCalls.map { $0.timeSpent }.reduce(0, +)
    }

    /// Time at which network response received.
    /// This time is asynchronous.
    @objc public fileprivate(set) var networkEndTime: TimeIntervalMillis = 0

    /// Message sent across the network.
    public fileprivate(set) var message: Message? = nil

    /// JSON representation of `message`.
    @objc public lazy var messageJSON: String = {
      guard let message = message else { return "" }
      do { return try message.jsonString() } catch { return "'ERROR'" }
    } ()

    /// Serialized bytes for `message` sent across the network.
    @objc public lazy var messageBytes: Data = {
      guard let message = message else { return Data() }
      do { return try message.serializedData() } catch { return Data() }
    } ()

    /// Total number of serialized bytes sent across network.
    /// This count is an approximation of actual network traffic.
    /// Network traffic also include HTTP headers, which are not
    /// counted in this size.
    @objc public lazy var messageSizeBytes: UInt64 = {
      return UInt64(messageBytes.count)
    } ()

    /// Logging calls included in this batch.
    public fileprivate(set) var metricsLoggerCalls: [MetricsLoggerCall] = []

    /// Errors that resulted from this batch.
    public fileprivate(set) var error: Error? = nil
  }
  
  public static let networkBatchWindowMaxSize: Int = 100
  
  /// Number of network batches to keep in memory.
  @objc public var networkBatchWindowSize: Int {
    didSet {
      let max = Self.networkBatchWindowMaxSize
      networkBatchWindowSize = min(networkBatchWindowSize, max)
      if networkBatchWindowSize < networkBatches.count {
        networkBatches = Array(networkBatches.prefix(networkBatchWindowSize))
      }
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
  @objc public var metricsLoggerCalls: [MetricsLoggerCall] {
    return networkBatches.flatMap { $0.metricsLoggerCalls }
  }

  /// Flattened errors across `networkBatches`.
  @objc public var errors: [Error] {
    return networkBatches.compactMap { $0.error }
  }

  private var pendingCalls: [MetricsLoggerCall]
  private var pendingBatch: NetworkBatch?
  
  private let clock: Clock

  init(clock: Clock) {
    self.clock = clock

    self.networkBatchWindowSize = 10
    self.totalBytesSent = 0
    self.totalRequestsMade = 0
    self.totalTimeSpent = 0
    self.networkBatches = []
    self.pendingCalls = []
    self.pendingBatch = nil
  }
  
  // MARK: - Call
  func metricsLoggerCallWillStart(context: Context) {
    let call = MetricsLoggerCall()
    call.context = context
    #if DEBUG
    call.callStack = Thread.callStackSymbols
    #endif
    call.startTime = clock.nowMillis
    pendingCalls.append(call)
  }
  
  func metricsLoggerCallDidLog(message: Message) {
    guard let lastCall = pendingCalls.last else { return }
    lastCall.messages.append(message)
  }

  func metricsLoggerCallDidComplete() {
    guard let lastCall = pendingCalls.last else { return }
    lastCall.endTime = clock.nowMillis
  }
  
  // MARK: - Batch
  func metricsLoggerBatchWillStart() {
    if let leftoverBatch = pendingBatch {
      // Might be leftover if previous batch didn't make
      // any network calls.
      add(batch: leftoverBatch)
    }
    let pendingBatch = NetworkBatch()
    pendingBatch.startTime = clock.nowMillis
    pendingBatch.metricsLoggerCalls = pendingCalls
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
    if networkBatches.count > networkBatchWindowSize {
      networkBatches.removeFirst()
    }
  }
}

extension Xray.MetricsLoggerCall {
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
    let callCount = metricsLoggerCalls.count
    let eventCount = metricsLoggerCalls.flatMap { $0.messages }.count
    let messageSize = messageSizeBytes
    return "(\(timeSpent) ms, \(callCount) calls, \(eventCount) events, " +
           "\(messageSize) bytes)"
  }
}

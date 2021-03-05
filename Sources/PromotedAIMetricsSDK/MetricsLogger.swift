import Foundation
import SwiftProtobuf

#if canImport(UIKit)
import UIKit
#endif

/**
 Promoted event logging interface. Use instances of `MetricsLogger`
 to log events to Promoted's servers. Events are accumulated and sent
 in batches on a timer (see `ClientConfig.batchLoggingFlushInterval`).
 
 Typically, instances of `MetricsLogger`s are tied to a
 `MetricsLoggingService`, which configures the logging environment and
 maintains a `MetricLogger` for the lifetime of the service. See
 `MetricsLoggingService` for more information about the scope of the
 logger and the service.
 
 Clients must subclass this logger in order to support batch logging
 (see Subclassing).
 
 Events are represented as protobuf messages internally. By default,
 these messages are serialized to binary format for transmission over
 the network.
 
 Use from main thread only.
 
 # Usage
 To start a logging session, first call `startSession(userID:)` or
 `startSessionSignedOut()` to set up the user ID and log user ID
 for the session. You can call either `startSession` method more
 than once to begin a new session with the given user ID.
 
 Use `log(event:)` to enqueue an event for logging. When the batching
 timer fires, all events are delivered to the server via the
 `NetworkConnection`.
 
 If you want to deliver queued events immediately, say when your app
 enters the background, use `flush()`. It's not necessary for clients
 to call `flush()` to deliver queued events. Events are automatically
 delivered on a timer.
 
 ## Example:
 ~~~
 let logger = MetricsLogger(...)
 // Sets userID and logUserID for subsequent log() calls.
 logger.startSession(userID: myUserID)
 logger.log(event: myEvent)
 // Resets userID and logUserID.
 logger.startSession(userID: secondUserID)
 ~~~
 
 # Subclassing
 Currently, clients will need to subclass `MetricsLogger` to deliver
 client-specific batch messages. Subclasses must override the
 `batchLogMessage(events:)` method to do so. Other logging methods
 must also be implemented in subclasses if you need to log custom
 messages.
 
 ## Example:
 ~~~
 public class MyMetricsLogger: MetricsLogger {
   public func logImpression(impressionID: String) {
     var impression = MyImpressionMessage()
     impression.common =
         commonImpressionEvent(impressionID: impressionID)
     log(event: impression)
   }
   public override func batchLogMessage(events: [Message])
       -> Message? {
     var batchMessage = MyBatchMessage()
     for event in events {
       // Fill in fields of batch message.
     }
     return batchMessage
   }
 }
 ~~~
 */
@objc(PROMetricsLogger)
open class MetricsLogger: NSObject {

  private let clock: Clock
  private let config: ClientConfig
  private let connection: NetworkConnection
  public let idMap: IDMap
  private let store: PersistentStore

  /*visibleForTesting*/ var events: [Message]
  
  private let metricsLoggingURL: URL?
  /// Timer for pending batched log request.
  private var batchLoggingTimer: ScheduledTimer?

  /// User ID for this session. Will be updated when
  /// `startSession(userID:)` or `startSessionSignedOut()` is
  /// called.
  public private(set) var userID: String?
  
  /// Log user ID for this session. Will be updated when
  /// `startSession(userID:)` or `startSessionSignedOut()` is
  /// called.
  public private(set) var logUserID: String?

  public init(clientConfig: ClientConfig,
              clock: Clock,
              connection: NetworkConnection,
              idMap: IDMap,
              store: PersistentStore) {
    self.clock = clock
    self.config = clientConfig
    self.connection = connection
    self.idMap = idMap
    self.store = store
    self.events = []
    self.userID = nil
    self.logUserID = nil
    self.metricsLoggingURL = URL(string: config.metricsLoggingURL)
  }
  
  /// Starts a new session with the given `userID`.
  /// If the `userID` has changed from the last value written to
  /// persistent store, regenrates `logUserID` and caches the new
  /// values of both to persistent store.
  ///
  /// You can call this method multiple times, whenever the user's
  /// sign-in state changes.
  ///
  /// Either this method or `startSessionSignedOut()` should be
  /// called before logging any events.
  public func startSession(userID: String) {
    startSessionAndUpdateUserIDs(userID: userID)
  }
  
  /// Starts a new session with signed-out user.
  /// Updates `userID` to `nil` and generates a new `logUserID`
  /// for the session. Writes the new values to persistent store.
  ///
  /// You can call this method multiple times, whenever the user's
  /// sign-in state changes.
  ///
  /// Either this method or `startSession(userID:)` should be
  /// called before logging any events.
  public func startSessionSignedOut() {
    startSessionAndUpdateUserIDs(userID: nil)
  }
  
  private func startSessionAndUpdateUserIDs(userID: String?) {
    self.userID = userID
    if let cachedLogUserID = store.logUserID {
      if userID == store.userID {
        self.logUserID = cachedLogUserID
        return
      }
    }
    store.userID = userID
    let newLogUserID = idMap.logUserID(userID: userID)
    store.logUserID = newLogUserID
    self.logUserID = newLogUserID
  }

  /// Enqueues the given message for logging. Messages are then
  /// delivered to the server on a timer.
  public func log(event: Message) {
    events.append(event)
    maybeSchedulePendingBatchLoggingFlush()
  }

  /// Subclasses should override to provide batch messages for the
  /// given list of events. Returning `nil` will abort the log.
  open func batchLogMessage(events: [Message]) -> Message? {
    // TODO(yu-hong): Update if we have a common batch message.
    return nil
  }
  
  private func maybeSchedulePendingBatchLoggingFlush() {
    if batchLoggingTimer != nil { return }
    let interval = config.batchLoggingFlushInterval
    batchLoggingTimer = clock.schedule(timeInterval: interval) { [weak self] clock in
      guard let strongSelf = self else { return }
      strongSelf.batchLoggingTimer = nil
      strongSelf.flush()
    }
  }
  
  private func cancelPendingBatchLoggingFlush() {
    if let timer = batchLoggingTimer {
      clock.cancel(scheduledTimer: timer)
      batchLoggingTimer = nil
    }
  }

  /// Delivers the set of pending events to server immediately.
  /// Call this method when your app enters the background to ensure
  /// consistent delivery of messages. Clients do NOT need to call
  /// this method for normal delivery of messages, as messages are
  /// batched and delivered automatically on a timer.
  ///
  /// Internally, a `UIBackgroundTask` is created during this operation.
  /// Clients do not need to start a `UIBackgroundTask` to call `flush()`.
  @objc public func flush() {
    cancelPendingBatchLoggingFlush()
    if events.isEmpty { return }

    let eventsCopy = events
    events.removeAll()
    guard let batchMessage = batchLogMessage(events: eventsCopy) else { return }
    guard let url = metricsLoggingURL else { return }
    do {
      try connection.sendMessage(batchMessage, url: url, clientConfig: config) {
          [weak self] (data, error) in
        if let e = error  {
          self?.handleSendMessageError(e)
          return
        }
        print("Fetch finished: \(String(describing: data))")
      }
    } catch NetworkConnectionError.messageSerializationError(let message) {
      print(message)
    } catch NetworkConnectionError.unknownError {
      print("ERROR: Unknown NetworkConnectionError sending message.")
    } catch {
      print("ERROR: Unknown error sending message.")
    }
  }
  
  private func handleSendMessageError(_ error: Error) {
    switch error {
    case NetworkConnectionError.networkSendError(let domain, let code, let errorString):
      print("ERROR: domain=\(domain) code=\(code) description=\(errorString)")
    default:
      print("ERROR: \(error.localizedDescription)")
    }
  }
}

// MARK: - Common events
public extension MetricsLogger {
  
  func commonUserEvent() -> Event_User {
    var user = Event_User()
    if let id = userID { user.userID = id }
    if let id = logUserID { user.logUserID = id }
    user.clientLogTimestamp = clock.nowMillis
    return user
  }

  func commonImpressionEvent(
      impressionID: String,
      insertionID: String? = nil,
      requestID: String? = nil,
      sessionID: String? = nil,
      viewID: String? = nil) -> Event_Impression {
    var impression = Event_Impression()
    impression.clientLogTimestamp = clock.nowMillis
    impression.impressionID = impressionID
    if let id = insertionID { impression.insertionID = id }
    if let id = requestID { impression.requestID = id }
    if let id = sessionID { impression.sessionID = id }
    if let id = viewID { impression.viewID = id }
    return impression
  }
  
  func commonClickEvent(
      clickID: String,
      impressionID: String? = nil,
      insertionID: String? = nil,
      requestID: String? = nil,
      sessionID: String? = nil,
      viewID: String? = nil,
      name: String? = nil,
      targetURL: String? = nil,
      elementID: String? = nil) -> Event_Click {
    var click = Event_Click()
    click.clientLogTimestamp = clock.nowMillis
    click.clickID = clickID
    if let id = impressionID { click.impressionID = id }
    if let id = insertionID { click.insertionID = id }
    if let id = requestID { click.requestID = id }
    if let id = sessionID { click.sessionID = id }
    if let id = viewID { click.viewID = id }
    if let s = name { click.name = s }
    if let u = targetURL { click.targetURL = u }
    if let id = elementID { click.elementID = id }
    return click
  }
  
  func commonViewEvent(
      viewID: String,
      sessionID: String? = nil,
      name: String? = nil,
      url: String? = nil,
      useCase: Event_UseCase? = nil) -> Event_View {
    var view = Event_View()
    view.clientLogTimestamp = clock.nowMillis
    view.viewID = viewID
    if let id = sessionID { view.sessionID = id }
    if let n = name { view.name = n }
    if let u = url { view.url = u }
    if let use = useCase { view.useCase = use }
    return view
  }
}

// MARK: - View controller logging
public extension MetricsLogger {
  /// `UIViewController` if `UIKit` is supported on build platform,
  /// `AnyObject` otherwise. Allows us to unit test on macOS.
  #if canImport(UIKit)
  typealias ViewControllerType = UIViewController
  #else
  typealias ViewControllerType = AnyObject
  #endif
  
  func loggingNameFor(viewController: ViewControllerType) -> String {
    let className = String(describing: type(of: viewController))
    let loggingName = className.replacingOccurrences(of:"ViewController", with: "")
    if loggingName.isEmpty { return "Unnamed" }
    return loggingName
  }
}

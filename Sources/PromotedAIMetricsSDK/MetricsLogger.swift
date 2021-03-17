import Foundation
import SwiftProtobuf

#if canImport(UIKit)
import UIKit
#endif

// MARK: -
/** Provides client-specific log messages to `MetricsLogger`. */
public protocol MessageProvider {

  /// Creates a client-specific user event.
  /// Don't fill out any fields on the returned value.
  func userMessage() -> User

  /// Creates a client-specific impression event.
  /// Don't fill out any fields on the returned value.
  func impressionMessage() -> Impression

  /// Creates a client-specific click event.
  /// Don't fill out any fields on the returned value.
  func clickMessage() -> Click

  /// Creates a client-specific view event.
  /// Don't fill out any fields on the returned value.
  func viewMessage() -> View

  /// Creates a batch message for the given list of events.
  /// Make sure to set the `userID` and `logUserID` fields in your
  /// returned message.
  func batchLogMessage(events: [Message],
                       userID: String?,
                       logUserID: String?) -> Message
}

// MARK: -
/**
 Promoted event logging interface. Use instances of `MetricsLogger`
 to log events to Promoted's servers. Events are accumulated and sent
 in batches on a timer (see `ClientConfig.batchLoggingFlushInterval`).
 
 Typically, instances of `MetricsLogger`s are tied to a
 `MetricsLoggingService`, which configures the logging environment and
 maintains a `MetricLogger` for the lifetime of the service. See
 `MetricsLoggingService` for more information about the scope of the
 logger and the service.
 
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
 
 # `MessageProvider`
 Clients must implement `MessageProvider` and supply `MetricsLogger`
 with the provider.
  
 ## Example:
 ~~~
 public class MyProvider: MessageProvider {
   public func impressionMessage() -> MyImpressionMessage {
     return MyImpressionMessage()
   }
   public func batchLogMessage(events: [Message],
                               userID: String?,
                               logUserID: String?) -> Message? {
     var batchMessage = MyBatchMessage()
     if let id = userID { batchMessage.userID = id }
     if let id = logUserID { batchMessage.logUserID = id }
     for event in events {
       // Fill in fields of batch message.
     }
     return batchMessage
   }
 }
 
 let logger = MetricsLogger(messageProvider: MyProvider(), ...)
 ~~~
 */
@objc(PROMetricsLogger)
public class MetricsLogger: NSObject {

  #if canImport(UIKit)
  public typealias ViewControllerType = UIViewController
  #else
  public typealias ViewControllerType = AnyObject
  #endif
  
  private let clock: Clock
  private let config: ClientConfig
  private let connection: NetworkConnection
  private let idMap: IDMap
  private let store: PersistentStore
  
  private let provider: MessageProvider

  /*visibleForTesting*/ private(set) var logMessages: [Message]
  
  private let metricsLoggingURL: URL?
  /// Timer for pending batched log request.
  private var batchLoggingTimer: ScheduledTimer?

  /// User ID for this session. Will be updated when
  /// `startSession(userID:)` or `startSessionSignedOut()` is
  /// called.
  /*visibleForTesting*/ private(set) var userID: String?
  
  /// Log user ID for this session. Will be updated when
  /// `startSession(userID:)` or `startSessionSignedOut()` is
  /// called.
  /*visibleForTesting*/ private(set) var logUserID: String?

  public init(messageProvider: MessageProvider,
              clientConfig: ClientConfig,
              clock: Clock,
              connection: NetworkConnection,
              idMap: IDMap,
              store: PersistentStore) {
    self.provider = messageProvider
    self.clock = clock
    self.config = clientConfig
    self.connection = connection
    self.idMap = idMap
    self.store = store
    self.logMessages = []
    self.userID = nil
    self.logUserID = nil
    self.metricsLoggingURL = URL(string: config.metricsLoggingURL)
  }
  
  // MARK: - Starting new sessions
  /// Call when sign-in completes with specified user ID.
  /// Starts logging session with the provided user and logs a
  /// user event.
  @objc(startSessionAndLogUserWithID:)
  public func startSessionAndLogUser(userID: String) {
    startSession(userID: userID)
    logUser()
  }

  /// Call when sign-in completes with no user.
  /// Starts logging session with signed-out user and logs a
  /// user event.
  @objc public func startSessionAndLogSignedOutUser() {
    startSessionSignedOut()
    logUser()
  }
  
  public func logUser() {
    let event = provider.userMessage()
    event.fillCommon(timestamp: clock.nowMillis,
                     userID: userID,
                     logUserID: logUserID)
    log(event: event)
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
  /*visibleForTesting*/ func startSession(userID: String) {
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
  /*visibleForTesting*/ func startSessionSignedOut() {
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
  
  // MARK: - Impressions
  /// Logs an impression for the given content.
  @objc public func logImpression(content: Content) {
    let event = provider.impressionMessage()
    let impressionID = idMap.impressionID(contentID: content.contentID)
    event.fillCommon(timestamp: clock.nowMillis,
                     impressionID: impressionID,
                     insertionID: content.insertionID)
    log(event: event)
  }

  // MARK: - Clicks
  /// Logs a click to like/unlike the given item.
  @objc(logClickToLikeItem:didLike:)
  public func logClickToLike(content: Content, didLike: Bool) {
    let actionName = didLike ? "like" : "unlike"
    logClick(actionName: actionName, contentID: content.contentID,
             insertionID: content.insertionID)
  }

  /// Logs a click to show the given view controller.
  @objc(logClickToShowViewController:)
  public func logClickToShow(viewController: ViewControllerType) {
    logClickToShow(name: loggingNameFor(viewController: viewController),
                   optionalContent: nil)
  }

  /// Logs a click to show the given view controller.
  @objc(logClickToShowViewController:forItem:)
  public func logClickToShow(viewController: ViewControllerType,
                             forContent content: Content) {
    logClickToShow(name: loggingNameFor(viewController: viewController),
                   optionalContent: content)
  }
  
  /// Logs a click to show a screen with given name.
  @objc(logClickToShowScreenName:)
  public func logClickToShow(screenName: String) {
    logClickToShow(name: screenName, optionalContent: nil)
  }
  
  /// Logs a click to show a screen with given name for given item.
  @objc(logClickToShowScreenName:forItem:)
  public func logClickToShow(screenName: String, forContent content: Content) {
    logClickToShow(name: screenName, optionalContent: content)
  }

  private func logClickToShow(name: String, optionalContent content: Content?) {
    logClick(actionName: name, contentID: content?.contentID,
             insertionID: content?.insertionID)
  }
  
  /// Logs a click to sign up as a new user.
  @objc public func logClickToSignUp(userID: String) {
    logClick(actionName: "sign-up", contentID: userID, insertionID: nil)
  }
  
  /// Logs a click to purchase the given item.
  @objc(logClickToPurchaseItem:)
  public func logClickToPurchase(item: Item) {
    logClick(actionName: "purchase", contentID: item.contentID,
             insertionID: item.insertionID)
  }
  
  /// Logs a click for the given action name.
  @objc public func logClick(actionName: String) {
    logClick(actionName: actionName, contentID: nil, insertionID: nil)
  }
  
  /// Logs a click for the given action name involving the given item.
  @objc public func logClick(actionName: String, content: Content) {
    logClick(actionName: actionName, contentID: content.contentID,
             insertionID: content.insertionID)
  }
  
  private func logClick(actionName: String,
                        contentID: String? = nil,
                        insertionID: String? = nil) {
    let event = provider.clickMessage()
    let impressionID = idMap.impressionIDOrNil(contentID: contentID)
    event.fillCommon(timestamp: clock.nowMillis,
                     clickID: idMap.clickID(),
                     impressionID: impressionID,
                     insertionID: insertionID,
                     targetURL: "#" + actionName,
                     elementID: actionName)
    log(event: event)
  }
  
  // MARK: - Views
  /// Logs a view of the given view controller.
  @objc public func logView(viewController: ViewControllerType) {
    let name = loggingNameFor(viewController: viewController)
    self.logView(name: name, optionalUseCase: nil)
  }
  
  /// Logs a view of the given view controller and use case.
  @objc public func logView(viewController: ViewControllerType,
                            useCase: UseCase) {
    let name = loggingNameFor(viewController: viewController)
    self.logView(name: name, optionalUseCase: useCase)
  }

  /// Logs a view of a screen with the given name.
  @objc public func logView(screenName: String) {
    self.logView(name: screenName, optionalUseCase: nil)
  }
  
  /// Logs a view of a screen with the given name and use case.
  @objc public func logView(screenName: String, useCase: UseCase) {
    self.logView(name: screenName, optionalUseCase: useCase)
  }
  
  private func logView(name: String, optionalUseCase: UseCase?) {
    let event = provider.viewMessage()
    let protoUseCase = (optionalUseCase != nil) ?
        Event_UseCase(rawValue: optionalUseCase!.rawValue) : nil
    let url = "#" + name
    event.fillCommon(timestamp: clock.nowMillis,
                     viewID: idMap.viewID(viewName: name),
                     name: name,
                     url: url,
                     useCase: protoUseCase)
    log(event: event)
  }
}

// MARK: - Sending events
public extension MetricsLogger {
  
  /// Enqueues the given event for logging. Messages are then
  /// delivered to the server on a timer.
  func log(event: AnyEvent) {
    if let clientMessage = event.messageForLogging() {
      log(message: clientMessage)
    }
  }

  /// Enqueues the given message for logging. Messages are then
  /// delivered to the server on a timer.
  func log(message: Message) {
    assert(Thread.isMainThread, "[MetricsLogger] Logging must be done on main thread")
    logMessages.append(message)
    maybeSchedulePendingBatchLoggingFlush()
  }
  
  private func maybeSchedulePendingBatchLoggingFlush() {
    if batchLoggingTimer != nil { return }
    let interval = config.batchLoggingFlushInterval
    batchLoggingTimer = clock.schedule(timeInterval: interval) {
        [weak self] clock in
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
  @objc func flush() {
    cancelPendingBatchLoggingFlush()
    if logMessages.isEmpty { return }

    let eventsCopy = logMessages
    logMessages.removeAll()
    let batchMessage = provider.batchLogMessage(events: eventsCopy,
                                                userID: userID,
                                                logUserID: logUserID)
    guard let url = metricsLoggingURL else { return }
    do {
      try connection.sendMessage(batchMessage, url: url, clientConfig: config) {
          [weak self] (data, error) in
        if let e = error  {
          self?.handleSendMessageError(e)
          return
        }
        print("[MetricsLogger] Fetch finished.")
      }
    } catch NetworkConnectionError.messageSerializationError(let message) {
      print(message)
    } catch NetworkConnectionError.unknownError {
      print("[MetricsLogger] ERROR: Unknown NetworkConnectionError sending message.")
    } catch {
      print("[MetricsLogger] ERROR: Unknown error sending message.")
    }
  }
  
  private func handleSendMessageError(_ error: Error) {
    switch error {
    case NetworkConnectionError.networkSendError(let domain, let code, let errorString):
      print("[MetricsLogger] ERROR: domain=\(domain) code=\(code) description=\(errorString)")
    default:
      print("[MetricsLogger] ERROR: \(error.localizedDescription)")
    }
  }
}

// MARK: - View controller logging
extension MetricsLogger {
  
  func loggingNameFor(viewController: ViewControllerType) -> String {
    let className = String(describing: type(of: viewController))
    let loggingName = className.replacingOccurrences(of:"ViewController", with: "")
    if loggingName.isEmpty { return "Unnamed" }
    return loggingName
  }
}

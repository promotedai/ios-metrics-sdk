import Foundation
import SwiftProtobuf

#if canImport(UIKit)
import UIKit
#endif

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
}

// MARK: - Event logging base methods
public extension MetricsLogger {
  /// Logs a user event.
  /// Autogenerates the following fields:
  /// - `clientLogTimestamp` from `clock.nowMillis`
  func logUser(userID: String? = nil,
               logUserID: String? = nil,
               payload: Message? = nil) {
    var user = Event_User()
    if let id = userID { user.userID = id }
    if let id = logUserID { user.logUserID = id }
    user.clientLogTimestamp = clock.nowMillis
    log(message: user)
  }

  /// Logs an impression event.
  /// Autogenerates the following fields:
  /// - `clientLogTimestamp` from `clock.nowMillis`
  /// - `impressionID` from `contentID`
  func logImpression(contentID: String,
                     insertionID: String? = nil,
                     requestID: String? = nil,
                     sessionID: String? = nil,
                     viewID: String? = nil,
                     payload: Message? = nil) {
    var impression = Event_Impression()
    impression.clientLogTimestamp = clock.nowMillis
    impression.impressionID = idMap.impressionID(contentID: contentID)
    if let id = insertionID { impression.insertionID = id }
    if let id = requestID { impression.requestID = id }
    if let id = sessionID { impression.sessionID = id }
    if let id = viewID { impression.viewID = id }
    log(message: impression)
  }
  
  /// Logs a click event.
  /// Autogenerates the following fields:
  /// - `clientLogTimestamp` from `clock.nowMillis`
  /// - `clickID` as a UUID
  /// - `impressionID` from `contentID`
  func logClick(actionName: String,
                contentID: String? = nil,
                insertionID: String? = nil,
                requestID: String? = nil,
                sessionID: String? = nil,
                viewID: String? = nil,
                name: String? = nil,
                targetURL: String? = nil,
                elementID: String? = nil,
                payload: Message? = nil) {
    var click = Event_Click()
    click.clientLogTimestamp = clock.nowMillis
    click.clickID = idMap.clickID()
    let impressionID = idMap.impressionIDOrNil(contentID: contentID)
    if let id = impressionID { click.impressionID = id }
    if let id = insertionID { click.insertionID = id }
    if let id = requestID { click.requestID = id }
    if let id = sessionID { click.sessionID = id }
    if let id = viewID { click.viewID = id }
    click.name = actionName
    click.targetURL = targetURL ?? "#" + actionName
    click.elementID = actionName
    log(message: click)
  }

  /// Logs a view event.
  /// Autogenerates the following fields:
  /// - `clientLogTimestamp` from `clock.nowMillis`
  /// - `viewID` from `name`
  func logView(name: String,
               sessionID: String? = nil,
               url: String? = nil,
               useCase: Event_UseCase? = nil,
               payload: Message? = nil) {
    var view = Event_View()
    view.clientLogTimestamp = clock.nowMillis
    view.viewID = idMap.viewID(viewName: name)
    if let id = sessionID { view.sessionID = id }
    view.name = name
    view.url = url ?? "#" + name
    if let use = useCase { view.useCase = use }
    log(message: view)
  }
}

public extension MetricsLogger {
  // MARK: - Impression logging helper methods
  /// Logs an impression for the given content.
  @objc func logImpression(content: Content) {
    if let id = content.contentID { logImpression(contentID: id) }
  }

  // MARK: - Click logging helper methods
  /// Logs a click to like/unlike the given item.
  @objc(logClickToLikeItem:didLike:)
  func logClickToLike(content: Content, didLike: Bool) {
    let actionName = didLike ? "like" : "unlike"
    logClick(actionName: actionName, contentID: content.contentID,
             insertionID: content.insertionID)
  }

  /// Logs a click to show the given view controller.
  @objc(logClickToShowViewController:)
  func logClickToShow(viewController: ViewControllerType) {
    logClickToShow(name: loggingNameFor(viewController: viewController),
                   optionalContent: nil)
  }

  /// Logs a click to show the given view controller.
  @objc(logClickToShowViewController:forItem:)
  func logClickToShow(viewController: ViewControllerType,
                             forContent content: Content) {
    logClickToShow(name: loggingNameFor(viewController: viewController),
                   optionalContent: content)
  }
  
  /// Logs a click to show a screen with given name.
  @objc(logClickToShowScreenName:)
  func logClickToShow(screenName: String) {
    logClickToShow(name: screenName, optionalContent: nil)
  }
  
  /// Logs a click to show a screen with given name for given item.
  @objc(logClickToShowScreenName:forItem:)
  func logClickToShow(screenName: String, forContent content: Content) {
    logClickToShow(name: screenName, optionalContent: content)
  }

  private func logClickToShow(name: String, optionalContent content: Content?) {
    logClick(actionName: name, contentID: content?.contentID,
             insertionID: content?.insertionID)
  }
  
  /// Logs a click to sign up as a new user.
  @objc func logClickToSignUp(userID: String) {
    logClick(actionName: "sign-up", contentID: userID, insertionID: nil)
  }
  
  /// Logs a click to purchase the given item.
  @objc(logClickToPurchaseItem:)
  func logClickToPurchase(item: Item) {
    logClick(actionName: "purchase", contentID: item.contentID,
             insertionID: item.insertionID)
  }
  
  /// Logs a click for the given action name.
  @objc func logClick(actionName: String) {
    logClick(actionName: actionName, contentID: nil, insertionID: nil)
  }
  
  /// Logs a click for the given action name involving the given item.
  @objc func logClick(actionName: String, content: Content) {
    logClick(actionName: actionName, contentID: content.contentID,
             insertionID: content.insertionID)
  }

  // MARK: - View logging helper methods
  /// Logs a view of the given view controller.
  @objc func logView(viewController: ViewControllerType) {
    let name = loggingNameFor(viewController: viewController)
    self.logView(name: name, useCase: nil)
  }
  
  /// Logs a view of the given view controller and use case.
  @objc func logView(viewController: ViewControllerType,
                     useCase: UseCase) {
    let name = loggingNameFor(viewController: viewController)
    self.logView(name: name, useCase: useCase.protoValue)
  }

  /// Logs a view of a screen with the given name.
  @objc func logView(screenName: String) {
    self.logView(name: screenName, useCase: nil)
  }
  
  /// Logs a view of a screen with the given name and use case.
  @objc func logView(screenName: String, useCase: UseCase) {
    self.logView(name: screenName, useCase: useCase.protoValue)
  }
}

// MARK: - Sending events
public extension MetricsLogger {

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
  
  private func logRequest(events: [Message]) -> Event_LogRequest {
    var logRequest = Event_LogRequest()
    if let id = userID { logRequest.userID = id }
    if let id = logUserID { logRequest.logUserID = id }
    for event in events {
      switch event {
      case let user as Event_User:
        logRequest.user.append(user)
      case let sessionProfile as Event_SessionProfile:
        logRequest.sessionProfile.append(sessionProfile)
      case let session as Event_Session:
        logRequest.session.append(session)
      case let view as Event_View:
        logRequest.view.append(view)
      case let request as Event_Request:
        logRequest.request.append(request)
      case let insertion as Event_Insertion:
        logRequest.insertion.append(insertion)
      case let impression as Event_Impression:
        logRequest.impression.append(impression)
      case let click as Event_Click:
        logRequest.click.append(click)
      default:
        print("Unknown event: \(event)")
      }
    }
    return logRequest
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
    let request = logRequest(events: eventsCopy)
    guard let url = metricsLoggingURL else { return }
    do {
      try connection.sendMessage(request, url: url, clientConfig: config) {
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

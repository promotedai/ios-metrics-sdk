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
  func userMessage<U: Message>() -> User<U>

  /// Creates a client-specific impression event.
  /// Don't fill out any fields on the returned value.
  func impressionMessage<I: Message>() -> Impression<I>

  /// Creates a client-specific click event.
  /// Don't fill out any fields on the returned value.
  func clickMessage<C: Message>() -> Click<C>

  /// Creates a client-specific view event.
  /// Don't fill out any fields on the returned value.
  func viewMessage<V: Message>() -> View<V>

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
    let event: AnyUser = provider.userMessage()
    event.fillCommon(timestamp: clock.nowMillis)
    log(event: event)
  }

  /// Call when sign-in completes with no user.
  /// Starts logging session with signed-out user and logs a
  /// user event.
  @objc public func startSessionAndLogSignedOutUser() {
    startSessionSignedOut()
    let event: AnyUser = provider.userMessage()
    event.fillCommon(timestamp: clock.nowMillis)
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
  
  // MARK: - Impressions
  /// Logs an impression for the given wardrobe item.
  @objc public func logImpression(item: Item) {
    let event: AnyImpression = provider.impressionMessage()
    let impressionID = idMap.impressionID(clientID: item.itemID)
    event.fillCommon(timestamp: clock.nowMillis,
                     impressionID: impressionID,
                     insertionID: item.insertionID)
    log(event: event)
  }

  // MARK: - Clicks
  /// Logs a click to like/unlike the given item.
  @objc(logClickToLikeItem:didLike:)
  public func logClickToLike(item: Item, didLike: Bool) {
    let event: AnyClick = provider.clickMessage()
    let targetURL = didLike ? "#like" : "#unlike"
    let elementID = didLike ? "like" : "unlike"
    event.fillCommon(timestamp: clock.nowMillis,
                     clickID: idMap.clickID(),
                     impressionID: idMap.impressionID(clientID: item.itemID),
                     insertionID: item.insertionID,
                     targetURL: targetURL,
                     elementID: elementID)
    log(event: event)
  }

  /// Logs a click to show the given view controller.
  @objc(logClickToShowViewController:forItem:)
  public func logClickToShow(viewController: ViewControllerType,
                             forItem item: Item) {
    let event: AnyClick = provider.clickMessage()
    let impressionID = idMap.impressionID(clientID: item.itemID)
    let targetURL = "#" + loggingNameFor(viewController: viewController)
    event.fillCommon(timestamp: clock.nowMillis,
                     clickID: idMap.clickID(),
                     impressionID: impressionID,
                     insertionID: item.insertionID,
                     targetURL: targetURL,
                     elementID: impressionID)  // Re-use impressionID for elementID.
    log(event: event)
  }
  
  /// Logs a click to sign up as a new user.
  @objc public func logClickToSignUp(userID: String) {
    let event: AnyClick = provider.clickMessage()
    event.fillCommon(timestamp: clock.nowMillis,
                     clickID: idMap.clickID(),
                     impressionID: idMap.impressionID(clientID: userID),
                     targetURL: "#sign-up",
                     elementID: "sign-up")
    log(event: event)
  }
  
  /// Logs a click to purchase the given item.
  @objc(logClickToPurchaseItem:)
  public func logClickToPurchase(item: Item) {
    let event: AnyClick = provider.clickMessage()
    let impressionID = idMap.impressionID(clientID: item.itemID)
    event.fillCommon(timestamp: clock.nowMillis,
                     clickID: idMap.clickID(),
                     impressionID: impressionID,
                     targetURL: "#purchase",
                     elementID: "purchase")
    log(event: event)
  }
  
  // MARK: - Views
  /// Logs a view of the given view controller.
  @objc public func logView(viewController: ViewControllerType) {
    self.logView(viewController: viewController, optionalUseCase: nil)
  }
  
  /// Logs a view of the given view controller and use case.
  @objc public func logView(viewController: ViewControllerType,
                            useCase: UseCase) {
    self.logView(viewController: viewController, optionalUseCase: useCase)
  }
  
  private func logView(viewController: ViewControllerType,
                       optionalUseCase: UseCase?) {
    let event: AnyView = provider.viewMessage()
    let name = loggingNameFor(viewController: viewController)
    let protoUseCase = (optionalUseCase != nil ?
                        Event_UseCase(rawValue: optionalUseCase!.rawValue) : nil)
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
  
  func log(event: AnyEvent) {
    if let clientMessage = event.messageForLogging() {
      log(message: clientMessage)
    }
  }

  /// Enqueues the given message for logging. Messages are then
  /// delivered to the server on a timer.
  func log(message: Message) {
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

// MARK: - View controller logging
extension MetricsLogger {
  /// `UIViewController` if `UIKit` is supported on build platform,
  /// `AnyObject` otherwise. Allows us to unit test on macOS.
  #if canImport(UIKit)
  public typealias ViewControllerType = UIViewController
  #else
  public typealias ViewControllerType = AnyObject
  #endif
  
  func loggingNameFor(viewController: ViewControllerType) -> String {
    let className = String(describing: type(of: viewController))
    let loggingName = className.replacingOccurrences(of:"ViewController", with: "")
    if loggingName.isEmpty { return "Unnamed" }
    return loggingName
  }
}

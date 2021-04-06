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
 
 Use `log(message:)` to enqueue an event for logging. When the batching
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
  private let deviceInfo: DeviceInfo
  private let idMap: IDMap
  private let store: PersistentStore

  /*visibleForTesting*/ private(set) var logMessages: [Message]
  
  /// Timer for pending batched log request.
  private var batchLoggingTimer: ScheduledTimer?

  /// User ID for this session. Will be updated when
  /// `startSession(userID:)` or `startSessionSignedOut()` is
  /// called.
  /*visibleForTesting*/ private(set) var userID: String?
  
  /// Log user ID for this session. Will be updated when
  /// `startSession(userID:)` or `startSessionSignedOut()` is
  /// called.
  public private(set) var logUserID: String?
  
  /// Session ID for this session. Will be updated when
  /// `startSession(userID:)` or `startSessionSignedOut()` is
  /// called.
  public private(set) var sessionID: String?
  
  private lazy var deviceMessage: Event_Device = {
    var device = Event_Device()
    if let type = deviceInfo.deviceType.protoValue { device.deviceType = type }
    device.brand = deviceInfo.brand
    device.manufacturer = deviceInfo.manufacturer
    device.identifier = deviceInfo.identifier
    device.osVersion = deviceInfo.osVersion
    device.locale.languageCode = deviceInfo.languageCode
    device.locale.regionCode = deviceInfo.regionCode
    let (width, height) = deviceInfo.screenSizePx
    device.screen.size.width = width
    device.screen.size.height = height
    device.screen.scale = deviceInfo.screenScale
    return device
  } ()

  init(clientConfig: ClientConfig,
       clock: Clock,
       connection: NetworkConnection,
       deviceInfo: DeviceInfo,
       idMap: IDMap,
       store: PersistentStore) {
    self.clock = clock
    self.config = clientConfig
    self.connection = connection
    self.deviceInfo = deviceInfo
    self.idMap = idMap
    self.store = store
    self.logMessages = []
    self.userID = nil
    self.logUserID = nil
    self.sessionID = nil
  }
  
  // MARK: - Starting new sessions
  /// Call when sign-in completes with specified user ID.
  /// Starts logging session with the provided user and logs a
  /// user event.
  @objc(startSessionAndLogUserWithID:)
  public func startSessionAndLogUser(userID: String) {
    startSession(userID: userID)
    logUser()
    logSession()
  }

  /// Call when sign-in completes with no user.
  /// Starts logging session with signed-out user and logs a
  /// user event.
  @objc public func startSessionAndLogSignedOutUser() {
    startSessionSignedOut()
    logUser()
    logSession()
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
    self.sessionID = idMap.sessionID()
    self.userID = userID
    if let cachedLogUserID = store.logUserID {
      if userID == store.userID {
        self.logUserID = cachedLogUserID
        return
      }
    }
    store.userID = userID
    let newLogUserID = idMap.logUserID()
    store.logUserID = newLogUserID
    self.logUserID = newLogUserID
  }
  
  private func userInfoMessage() -> Common_UserInfo {
    assert(logUserID != nil, "Call startSession* before any log* methods")
    var userInfo = Common_UserInfo()
    if let id = userID { userInfo.userID = id }
    if let id = logUserID { userInfo.logUserID = id }
    return userInfo
  }
  
  private func timingMessage() -> Common_Timing {
    var timing = Common_Timing()
    timing.clientLogTimestamp = clock.nowMillis
    return timing
  }

  private static func propertiesWrapperMessage(_ message: Message?)
      -> Common_Properties? {
    do {
      if let message = message {
        var dataMessage = Common_Properties()
        try dataMessage.structBytes = message.serializedData()
        return dataMessage
      }
    } catch BinaryEncodingError.missingRequiredFields {
      print("[MetricsLogger] Payload missing required fields: " +
            String(describing: message))
    } catch {
      print("[MetricsLogger] Unknown error serializing data")
    }
    return nil
  }
}

// MARK: - Event logging base methods
public extension MetricsLogger {
  /// Logs a user event.
  ///
  /// Autogenerates the following fields:
  /// - `userID` from the state in this object
  /// - `logUserID` from the state in this object
  /// - `clientLogTimestamp` from `clock.nowMillis`
  ///
  /// - Parameters:
  ///   - data: Client-specific message
  func logUser(properties: Message? = nil) {
    var user = Event_User()
    user.timing = timingMessage()
    if let properties = Self.propertiesWrapperMessage(properties) {
      user.properties = properties
    }
    log(message: user)
  }
  
  func logSession(properties: Message? = nil) {
    assert(sessionID != nil, "Call startSession* before any log* methods")
    var session = Event_Session()
    session.timing = timingMessage()
    if let id = sessionID { session.sessionID = id }
    session.startEpochMillis = clock.nowMillis
    if let properties = Self.propertiesWrapperMessage(properties) {
      session.properties = properties
    }
    log(message: session)
  }

  /// Logs an impression event.
  ///
  /// Autogenerates the following fields:
  /// - `clientLogTimestamp` from `clock.nowMillis`
  /// - `impressionID` from `contentID`
  ///
  /// - Parameters:
  ///   - contentID: Content ID from which to derive `impressionID`
  ///   - insertionID: Insertion ID as provided by Promoted
  ///   - data: Client-specific message
  func logImpression(contentID: String? = nil,
                     insertionID: String? = nil,
                     requestID: String? = nil,
                     viewID: String? = nil,
                     properties: Message? = nil) {
    let optionalID = idMap.impressionIDOrNil(insertionID: insertionID,
                                             contentID: contentID,
                                             logUserID: logUserID)
    guard let impressionID = optionalID else { return }
    var impression = Event_Impression()
    impression.timing = timingMessage()
    impression.impressionID = impressionID
    if let id = insertionID { impression.insertionID = id }
    if let id = requestID { impression.requestID = id }
    if let id = sessionID { impression.sessionID = id }
    if let id = viewID { impression.viewID = id }
    if let id = contentID { impression.contentID = idMap.contentID(clientID: id) }
    if let properties = Self.propertiesWrapperMessage(properties) {
      impression.properties = properties
    }
    log(message: impression)
  }
  
  /// Logs a click event.
  ///
  /// Autogenerates the following fields:
  /// - `clientLogTimestamp` from `clock.nowMillis`
  /// - `clickID` as a UUID
  /// - `impressionID` from `contentID`
  /// - `name` from `actionName`
  /// - If no `targetURL` is provided, `targetURL` is derived from `name`
  /// - If no `elementID` is provided, `elementID` is derived from `name`
  ///
  /// - Parameters:
  ///   - name: Name for action to log, human readable
  ///   - contentID: Content ID from which to derive `impressionID`
  ///   - insertionID: Insertion ID as provided by Promoted
  ///   - data: Client-specific message
  func logAction(name: String,
                 type: ActionType,
                 contentID: String? = nil,
                 insertionID: String? = nil,
                 requestID: String? = nil,
                 viewID: String? = nil,
                 targetURL: String? = nil,
                 elementID: String? = nil,
                 properties: Message? = nil) {
    var action = Event_Action()
    action.timing = timingMessage()
    action.actionID = idMap.actionID()
    let impressionID = idMap.impressionIDOrNil(insertionID: insertionID,
                                               contentID: contentID,
                                               logUserID: logUserID)
    if let id = impressionID { action.impressionID = id }
    if let id = insertionID { action.insertionID = id }
    if let id = requestID { action.requestID = id }
    if let id = sessionID { action.sessionID = id }
    if let id = viewID { action.viewID = id }
    action.name = name
    if let type = type.protoValue { action.actionType = type }
    action.elementID = name
    switch type {
    case .navigate:
      var navigateAction = Event_NavigateAction()
      if let url = targetURL { navigateAction.targetURL = url }
      action.navigateAction = navigateAction
    default:
      break
    }
    if let properties = Self.propertiesWrapperMessage(properties) {
      action.properties = properties
    }
    log(message: action)
  }

  /// Logs a view event.
  ///
  /// Autogenerates the following fields:
  /// - `clientLogTimestamp` from `clock.nowMillis`
  /// - `viewID` from `name`
  /// - If no `url` is provided, `url` is derived from `name`
  ///
  /// - Parameters:
  ///   - name: Name for view, human readable
  ///   - url: URL for the view, can contain options for the view
  ///   - useCase: Use case for view
  ///   - data: Client-specific message
  func logView(name: String,
               useCase: UseCase? = nil,
               properties: Message? = nil) {
    var view = Event_View()
    view.timing = timingMessage()
    view.viewID = idMap.viewID()
    if let id = sessionID { view.sessionID = id }
    view.name = name
    if let use = useCase?.protoValue { view.useCase = use }
    if let properties = Self.propertiesWrapperMessage(properties) {
      view.properties = properties
    }
    view.device = deviceMessage
    view.viewType = .appScreen
    let appScreenView = Event_AppScreenView()
    view.appScreenView = appScreenView
    log(message: view)
  }
}

// MARK: - Sending events
public extension MetricsLogger {

  /// Enqueues the given message for logging. Messages are then
  /// delivered to the server on a timer.
  func log(message: Message) {
    assert(Thread.isMainThread,
           "[MetricsLogger] Logging must be done on main thread")
    logMessages.append(message)
    maybeSchedulePendingBatchLoggingFlush()
  }
  
  private func maybeSchedulePendingBatchLoggingFlush() {
    if batchLoggingTimer != nil { return }
    let interval = config.loggingFlushInterval
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
  
  private func logRequestMessage(events: [Message]) -> Event_LogRequest {
    var logRequest = Event_LogRequest()
    logRequest.userInfo = userInfoMessage()
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
      case let request as Delivery_Request:
        logRequest.request.append(request)
      case let insertion as Delivery_Insertion:
        logRequest.insertion.append(insertion)
      case let impression as Event_Impression:
        logRequest.impression.append(impression)
      case let action as Event_Action:
        logRequest.action.append(action)
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
    if !config.loggingEnabled { return }

    let eventsCopy = logMessages
    logMessages.removeAll()
    let request = logRequestMessage(events: eventsCopy)
    do {
      try connection.sendMessage(request, clientConfig: config) {
          [weak self] (data, error) in
        if let e = error  {
          self?.handleSendMessageError(e)
          return
        }
        print("[MetricsLogger] Logging finished.")
      }
    } catch NetworkConnectionError.messageSerializationError(let message) {
      print("[MetricsLogger] \(message)")
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

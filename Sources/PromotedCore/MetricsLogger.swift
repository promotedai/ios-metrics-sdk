import Foundation
import SwiftProtobuf
import os.log

// MARK: -
/**
 Promoted event logging interface. Use instances of `MetricsLogger`
 to log events to Promoted's servers. Events are accumulated and sent
 in batches on a timer (see `ClientConfig.batchLoggingFlushInterval`).
 
 Typically, instances of `MetricsLogger`s are tied to a
 `MetricsLoggerService`, which configures the logging environment and
 maintains a `MetricsLogger` for the lifetime of the service. See
 `MetricsLoggerService` for more information about the scope of the
 logger and the service.
 
 Events are represented as protobuf messages internally. By default,
 these messages are serialized to binary format for transmission over
 the network.

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

 Use from main thread only.

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
public final class MetricsLogger: NSObject {

  private let clock: Clock
  private let config: ClientConfig
  private let connection: NetworkConnection
  private let deviceInfo: DeviceInfo
  private let idMap: IDMap
  private let store: PersistentStore

  private var logMessages: [Message]
  
  /// Timer for pending batched log request.
  private var batchLoggingTimer: ScheduledTimer?

  /// User ID for this session. Will be updated when
  /// `startSession(userID:)` or `startSessionSignedOut()` is
  /// called.
  private var userID: String?
  
  private let logUserIDProducer: IDProducer
  private let sessionIDProducer: IDProducer
  let viewTracker: ViewTracker
  private var needsViewStateCheck: Bool

  private unowned let monitor: OperationMonitor
  private let osLog: OSLog?

  private lazy var cachedDeviceMessage: Event_Device = deviceMessage()
  private lazy var cachedLocaleMessage: Event_Locale = localeMessage()

  typealias Deps = ClientConfigSource & ClockSource & NetworkConnectionSource &
                   DeviceInfoSource & IDMapSource & OperationMonitorSource &
                   OSLogSource & PersistentStoreSource & ViewTrackerSource

  init(deps: Deps) {
    self.clock = deps.clock
    self.config = deps.clientConfig
    self.connection = deps.networkConnection
    self.deviceInfo = deps.deviceInfo
    self.idMap = deps.idMap
    self.monitor = deps.operationMonitor
    self.store = deps.persistentStore
    self.osLog = deps.osLog(category: "MetricsLogger")

    self.logMessages = []
    self.userID = nil

    self.logUserIDProducer = IDProducer(initialValueProducer: {
      [store, idMap] in store.logUserID ?? idMap.logUserID()
    }, nextValueProducer: {
      [idMap] in idMap.logUserID()
    })
    self.sessionIDProducer = IDProducer { [idMap] in idMap.sessionID() }
    self.viewTracker = deps.viewTracker
    self.needsViewStateCheck = false

    super.init()
    self.monitor.addOperationMonitorListener(self)
  }
}

// MARK: - Ancestor IDs
public extension MetricsLogger {
  /// Log user ID for this session. Updated when
  /// `startSession(userID:)` or `startSessionSignedOut()` is
  /// called. If read before the first call to `startSession*`,
  /// returns the cached ID from the previous session from
  /// `PeristentStore`.
  var logUserID: String {
    get { logUserIDProducer.currentValue }
    set { logUserIDProducer.currentValue = newValue }
  }

  private var ancestorLogUserID: String? {
    logUserIDProducer.currentValueForAncestorID
  }

  /// Session ID for this session. Updated when
  /// `startSession(userID:)` or `startSessionSignedOut()` is
  /// called. If read before the first call to `startSession*`,
  /// returns an ID that will be used for the first session.
  var sessionID: String {
    get { sessionIDProducer.currentValue }
    set { sessionIDProducer.currentValue = newValue }
  }

  private var ancestorSessionID: String? {
    sessionIDProducer.currentValueForAncestorID
  }

  /// View ID for current view. Updated when `logView()` is
  /// called. If read before the first call to `logView()`,
  /// returns an ID that will be used for the first view.
  ///
  /// When called internally by `MetricsLogger`, may cause
  /// a View event to be logged.
  var viewID: String {
    return viewTracker.viewID
  }

  private var ancestorViewID: String? {
    if needsViewStateCheck {
      needsViewStateCheck = false
      if let state = viewTracker.updateState() {
        logView(trackerState: state)
      }
    }
    return viewTracker.viewIDForAncestorID
  }
}

// MARK: - Starting new sessions
public extension MetricsLogger {
  /// Call when sign-in completes with specified user ID.
  /// Starts logging session with the provided user and logs a
  /// user event.
  @objc(startSessionAndLogUserWithID:)
  func startSessionAndLogUser(userID: String) {
    monitor.execute {
      startSession(userID: userID)
      logUser()
    }
  }

  /// Call when sign-in completes with no user.
  /// Starts logging session with signed-out user and logs a
  /// user event.
  @objc func startSessionAndLogSignedOutUser() {
    monitor.execute {
      startSessionSignedOut()
      logUser()
    }
  }

  /// Starts a new session with the given `userID`.
  /// If the `userID` has changed from the last value written to
  /// persistent store, regenrates `logUserID` and caches the new
  /// values of both to persistent store. Also creates new `sessionID`.
  ///
  /// You can call this method multiple times, whenever the user's
  /// sign-in state changes.
  ///
  /// Either this method or `startSessionSignedOut()` should be
  /// called before logging any events.
  private func startSession(userID: String) {
    startSessionAndUpdateUserIDs(userID: userID)
  }
  
  /// Starts a new session with signed-out user.
  /// Updates `userID` to `nil` and generates a new `logUserID`
  /// for the session. Writes the new values to persistent store.
  /// Also creates new `sessionID`.
  ///
  /// You can call this method multiple times, whenever the user's
  /// sign-in state changes.
  ///
  /// Either this method or `startSession(userID:)` should be
  /// called before logging any events.
  private func startSessionSignedOut() {
    startSessionAndUpdateUserIDs(userID: nil)
  }
  
  private func startSessionAndUpdateUserIDs(userID: String?) {
    sessionIDProducer.nextValue()

    // New session with same user should not regenerate logUserID.
    if (self.userID != nil) && (self.userID == userID) { return }

    self.userID = userID
    store.userID = userID

    // Reads logUserID from store for initial value, if available.
    store.logUserID = logUserIDProducer.nextValue()
  }
}

// MARK: - Internal methods
fileprivate extension MetricsLogger {
  private func deviceMessage() -> Event_Device {
    var device = Event_Device()
    if let type = deviceInfo.deviceType.protoValue { device.deviceType = type }
    device.brand = deviceInfo.brand
    device.manufacturer = deviceInfo.manufacturer
    device.identifier = deviceInfo.identifier
    device.osVersion = deviceInfo.osVersion
    let (width, height) = deviceInfo.screenSizePx
    device.screen.size.width = width
    device.screen.size.height = height
    device.screen.scale = deviceInfo.screenScale
    return device
  }

  private func localeMessage() -> Event_Locale {
    var locale = Event_Locale()
    locale.languageCode = deviceInfo.languageCode
    locale.regionCode = deviceInfo.regionCode
    return locale
  }

  private func userInfoMessage() -> Common_UserInfo {
    var userInfo = Common_UserInfo()
    if let id = userID { userInfo.userID = id }
    if let id = ancestorLogUserID { userInfo.logUserID = id }
    return userInfo
  }
  
  private func timingMessage() -> Common_Timing {
    var timing = Common_Timing()
    timing.clientLogTimestamp = UInt64(clock.nowMillis)
    return timing
  }

  private func propertiesMessage(_ message: Message?) -> Common_Properties? {
    do {
      if let message = message {
        var dataMessage = Common_Properties()
        dataMessage.structBytes = try message.serializedData()
        return dataMessage
      }
    } catch {
      osLog?.error("propertiesMessage: %{private}@", error.localizedDescription)
      let wrapped = MetricsLoggerError.propertiesSerializationError(underlying: error)
      monitor.executionDidError(wrapped)
    }
    return nil
  }
}

// MARK: - Event logging base methods
public extension MetricsLogger {
  /// Logs a user event.
  ///
  /// Autogenerates the following fields:
  /// - `timing` from `clock.nowMillis`
  ///
  /// - Parameters:
  ///   - properties: Client-specific message
  func logUser(properties: Message? = nil) {
    monitor.execute {
      var user = Event_User()
      user.timing = timingMessage()
      if let p = propertiesMessage(properties) { user.properties = p }
      log(message: user)
    }
  }

  /// Logs an impression event.
  ///
  /// Autogenerates the following fields:
  /// - `timing` from `clock.nowMillis`
  /// - `impressionID` from a combination of `insertionID`,
  ///    `contentID`, and `logUserID`
  /// - `sessionID` from state in this logger
  /// - `viewID` from state in this logger
  ///
  /// - Parameters:
  ///   - contentID: Content ID from which to derive `impressionID`
  ///   - insertionID: Insertion ID as provided by Promoted
  ///   - properties: Client-specific message
  func logImpression(contentID: String? = nil,
                     insertionID: String? = nil,
                     requestID: String? = nil,
                     properties: Message? = nil) {
    monitor.execute {
      var impression = Event_Impression()
      impression.timing = timingMessage()
      impression.impressionID = idMap.impressionID()
      if let id = insertionID { impression.insertionID = id }
      if let id = requestID { impression.requestID = id }
      if let id = ancestorSessionID { impression.sessionID = id }
      if let id = ancestorViewID { impression.viewID = id }
      if let id = contentID { impression.contentID = idMap.contentID(clientID: id) }
      if let p = propertiesMessage(properties) { impression.properties = p }
      log(message: impression)
    }
  }
  
  /// Logs a user action event.
  ///
  /// Autogenerates the following fields:
  /// - `timing` from `clock.nowMillis`
  /// - `actionID` as a UUID
  /// - `impressionID` from a combination of `insertionID`,
  ///    `contentID`, and `logUserID`
  /// - `sessionID` from state in this logger
  /// - `viewID` from state in this logger
  /// - `name` from `actionName`
  /// - If no `elementID` is provided, `elementID` is derived from `name`
  ///
  /// - Parameters:
  ///   - name: Name for action to log, human readable
  ///   - contentID: Content ID from which to derive `impressionID`
  ///   - insertionID: Insertion ID as provided by Promoted
  ///   - properties: Client-specific message
  func logAction(name: String,
                 type: ActionType,
                 contentID: String? = nil,
                 insertionID: String? = nil,
                 requestID: String? = nil,
                 targetURL: String? = nil,
                 elementID: String? = nil,
                 properties: Message? = nil) {
    monitor.execute {
      var action = Event_Action()
      action.timing = timingMessage()
      action.actionID = idMap.actionID()
      if let id = insertionID { action.insertionID = id }
      if let id = requestID { action.requestID = id }
      if let id = ancestorSessionID { action.sessionID = id }
      if let id = ancestorViewID { action.viewID = id }
      action.name = name
      if let type = type.protoValue { action.actionType = type }
      action.elementID = elementID ?? name
      switch type {
      case .navigate:
        var navigateAction = Event_NavigateAction()
        if let url = targetURL { navigateAction.targetURL = url }
        action.navigateAction = navigateAction
      default:
        break
      }
      if let p = propertiesMessage(properties) { action.properties = p }
      log(message: action)
    }
  }

  /// Logs a view event if the given key causes a state change in
  /// the `ViewTracker`.
  ///
  /// Autogenerates the following fields:
  /// - `timing` from `clock.nowMillis`
  /// - `viewID` as a UUID when a new view is logged, re-used from
  ///    previous state when the key already exists
  /// - `sessionID` from state in this logger
  /// - `device` from `DeviceInfo` on current system
  ///
  /// - Parameters:
  ///   - trackerKey: ViewTracker.Key that specifies view.
  ///   - properties: Client-specific message
  internal func logView(trackerKey: ViewTracker.Key,
                        useCase: UseCase? = nil,
                        properties: Message? = nil) {
    if let state = viewTracker.trackView(key: trackerKey, useCase: useCase) {
      logView(trackerState: state, properties: properties)
    }
  }

  private func logView(trackerState: ViewTracker.State, properties: Message? = nil) {
    monitor.execute {
      var view = Event_View()
      view.timing = timingMessage()
      needsViewStateCheck = false  // No need for check when logging view.
      if let id = ancestorViewID { view.viewID = id }
      if let id = ancestorSessionID { view.sessionID = id }
      view.name = trackerState.name
      if let use = trackerState.useCase?.protoValue { view.useCase = use }
      if let p = propertiesMessage(properties) { view.properties = p }
      view.device = cachedDeviceMessage
      view.locale = cachedLocaleMessage
      view.viewType = .appScreen
      let appScreenView = Event_AppScreenView()
      // TODO(yu-hong): Fill out AppScreenView.
      view.appScreenView = appScreenView
      log(message: view)
    }
  }
}

// MARK: - Sending events
public extension MetricsLogger {

  /// Enqueues the given message for logging. Messages are then
  /// delivered to the server on a timer.
  func log(message: Message) {
    guard Thread.isMainThread else {
      osLog?.error("Logging must be done on main thread")
      monitor.executionDidError(MetricsLoggerError.calledFromWrongThread)
      return
    }
    logMessages.append(message)
    monitor.executionWillLog(message: message)
    maybeSchedulePendingBatchLoggingFlush()
  }

  private func maybeSchedulePendingBatchLoggingFlush() {
    if batchLoggingTimer != nil { return }
    let interval = config.loggingFlushInterval
    batchLoggingTimer = clock.schedule(timeInterval: interval) {
      [weak self] clock in
      guard let self = self else { return }
      self.batchLoggingTimer = nil
      self.flush()
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
        osLog?.debug("Unknown event: %{private}@", String(describing: event))
        monitor.executionDidError(MetricsLoggerError.unexpectedEvent(event))
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
    guard !logMessages.isEmpty else { return }

    monitor.execute(context: .batch) {
      let eventsCopy = logMessages
      logMessages.removeAll()
      let request = logRequestMessage(events: eventsCopy)
      do {
        let data = try connection.sendMessage(request, clientConfig: config) {
          [weak self] (data, error) in
          self?.handleFlushResponse(data: data, error: error)
        }
        monitor.executionWillLog(message: request)
        monitor.executionWillLog(data: data)
      } catch {
        osLog?.error("flush: %{public}@", error.localizedDescription)
        monitor.executionDidError(error)
      }
    }
  }

  private func handleFlushResponse(data: Data?, error: Error?) {
    monitor.execute(context: .batchResponse) {
      osLog?.info("Logging finished")
      if let _ = data {
        monitor.executionDidLog()
      }
      if let e = error {
        osLog?.error("flush/sendMessage: %{public}@", e.localizedDescription)
        monitor.executionDidError(e)
      }
    }
  }
}

// MARK: - OperationMonitorListener

extension MetricsLogger: OperationMonitorListener {
  /// Ensures that the view ID is correct for the logging that
  /// occurs within the given block. This may involve a check that
  /// iterates through the UIView stack. This check occurs lazily
  /// on the first access of the `viewID` property. When called
  /// re-entrantly, only the first (outermost) call causes this
  /// view state check, since that check is relatively expensive.
  func executionWillStart(context: OperationMonitor.Context) {
    needsViewStateCheck = true
  }

  func executionDidEnd(context: OperationMonitor.Context) {
    needsViewStateCheck = false
  }
}

// MARK: - Testing
extension MetricsLogger {
  var logMessagesForTesting: [Message] { logMessages }
  var userIDForTesting: String? { userID }

  func startSessionForTesting(userID: String) {
    startSession(userID: userID)
  }

  func startSessionSignedOutForTesting() {
    startSessionSignedOut()
  }
}

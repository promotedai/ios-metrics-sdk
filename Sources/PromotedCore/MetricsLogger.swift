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
 ```swift
 let logger = MetricsLogger(...)
 // Sets userID and logUserID for subsequent log() calls.
 logger.startSession(userID: myUserID)
 logger.log(event: myEvent)
 // Resets userID and logUserID.
 logger.startSession(userID: secondUserID)
 ```
 */
@objc(PROMetricsLogger)
public final class MetricsLogger: NSObject {

  private unowned let clock: Clock
  private let config: ClientConfig
  private unowned let connection: NetworkConnection
  private unowned let deviceInfo: DeviceInfo
  private unowned let idMap: IDMap
  private unowned let monitor: OperationMonitor
  private let osLog: OSLog?
  private unowned let store: PersistentStore
  private unowned let xray: Xray?

  private var logMessages: [Message]
  
  /// Timer for pending batched log request.
  private var batchLoggingTimer: ScheduledTimer?

  /// User ID for this session. Will be updated when
  /// `startSession(userID:)` or `startSessionSignedOut()` is
  /// called.
  private var userID: String?
  
  private let logUserIDProducer: IDProducer
  private let sessionIDProducer: IDProducer
  private unowned let viewTracker: ViewTracker
  private var needsViewStateCheck: Bool

  var history: AncestorIDHistory?

  private lazy var cachedDeviceMessage: Common_Device = deviceMessage()
  private lazy var cachedLocaleMessage: Common_Locale = localeMessage()

  typealias Deps = (
    ClientConfigSource &
    ClockSource &
    DeviceInfoSource &
    IDMapSource &
    NetworkConnectionSource &
    OperationMonitorSource &
    OSLogSource &
    PersistentStoreSource &
    ViewTrackerSource &
    XraySource
  )

  init(deps: Deps) {
    clock = deps.clock
    config = deps.clientConfig
    connection = deps.networkConnection
    deviceInfo = deps.deviceInfo
    idMap = deps.idMap
    monitor = deps.operationMonitor
    store = deps.persistentStore
    osLog = deps.osLog(category: "MetricsLogger")
    xray = deps.xray

    logMessages = []
    userID = nil

    logUserIDProducer = IDProducer(
      initialValueProducer: {
        [store, idMap] in store.logUserID ?? idMap.logUserID()
      },
      nextValueProducer: {
        [idMap] in idMap.logUserID()
      }
    )
    sessionIDProducer = IDProducer { [idMap] in idMap.sessionID() }
    viewTracker = deps.viewTracker
    needsViewStateCheck = false

    history = config.diagnosticsIncludeAncestorIDHistory ?
      AncestorIDHistory(osLog: osLog, xray: xray) : nil

    super.init()
    monitor.addOperationMonitorListener(self)
  }
}

// MARK: - Ancestor IDs
public extension MetricsLogger {
  /// Log user ID for this session. Updated when
  /// `startSession(userID:)` or `startSessionSignedOut()` is
  /// called.
  var logUserID: String? {
    get { logUserIDProducer.currentValue }
    set {
      logUserIDProducer.currentValue = newValue
      history?.logUserIDDidChange(value: newValue)
    }
  }

  /// Log user ID for this session.
  /// If read before the first call to `startSession*`,
  /// returns the cached ID from the previous session from
  /// `PeristentStore`.
  var currentOrPendingLogUserID: String? {
    logUserIDProducer.currentOrPendingValue
  }

  /// Session ID for this session. Updated when
  /// `startSession(userID:)` or `startSessionSignedOut()` is
  /// called.
  var sessionID: String? {
    get { sessionIDProducer.currentValue }
    set {
      sessionIDProducer.currentValue = newValue
      history?.sessionIDDidChange(value: newValue)
    }
  }

  /// Session ID for this session.
  /// If read before the first call to `startSession*`,
  /// returns an ID that will be used for the first session.
  var currentOrPendingSessionID: String? {
    sessionIDProducer.currentOrPendingValue
  }

  /// View ID for current view. Updated when `logView()` is
  /// called.
  var viewID: String? {
    get {
      if needsViewStateCheck {
        needsViewStateCheck = false
        if let state = viewTracker.updateState() {
          logView(trackerState: state)
        }
      }
      return viewTracker.id.currentValue
    }
    set {
      viewTracker.id.currentValue = newValue
      history?.viewIDDidChange(value: newValue)
    }
  }

  /// View ID for current view.
  /// If read before the first call to `logView()`,
  /// returns an ID that will be used for the first view.
  var currentOrPendingViewID: String? {
    viewTracker.id.currentOrPendingValue
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
    sessionIDProducer.advance()

    // New session with same user should not regenerate logUserID.
    if (self.userID != nil) && (self.userID == userID) { return }

    self.userID = userID
    store.userID = userID

    // Reads logUserID from store for initial value, if available.
    store.logUserID = logUserIDProducer.advance()
  }
}

// MARK: - Internal methods
extension MetricsLogger {
  private func deviceMessage() -> Common_Device {
    var device = Common_Device()
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

  private func localeMessage() -> Common_Locale {
    var locale = Common_Locale()
    locale.languageCode = deviceInfo.languageCode
    locale.regionCode = deviceInfo.regionCode
    return locale
  }

  private func userInfoMessage() -> Common_UserInfo {
    var userInfo = Common_UserInfo()
    if let id = userID { userInfo.userID = id }
    if let id = logUserID { userInfo.logUserID = id }
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
      osLog?.error(
        "propertiesMessage: %{private}@",
        error.localizedDescription
      )
      let wrapped = MetricsLoggerError.propertiesSerializationError(
        underlying: error
      )
      monitor.executionDidError(wrapped)
    }
    return nil
  }

  private func setValue<T>(_ value: T?, in field: inout T) {
    if let value = value { field = value }
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
  /// - Returns:
  ///   Logged event message.
  @discardableResult
  internal func logUser(properties: Message? = nil) -> Event_User {
    var user = Event_User()
    monitor.execute {
      user.timing = timingMessage()
      setValue(propertiesMessage(properties), in: &user.properties)
      log(message: user)
      history?.logUserIDDidChange(value: logUserID, event: user)
      history?.sessionIDDidChange(value: sessionID)
    }
    return user
  }

  /// Logs an impression event.
  /// See also `ImpressionTracker` and `ScrollTracker` for more
  /// advanced impression tracking methods.
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
  ///   - requestID: Request ID as provided by Promoted
  ///   - viewID: View ID to set in impression. If not provided, defaults to
  ///     the view ID last logged via `logView`.
  ///   - sourceType: Origin of the impressed content
  ///   - properties: Client-specific message
  /// - Returns:
  ///   Logged event message.
  @discardableResult
  func logImpression(
    contentID: String? = nil,
    insertionID: String? = nil,
    requestID: String? = nil,
    viewID: String? = nil,
    autoViewID: String? = nil,
    sourceType: ImpressionSourceType? = nil,
    properties: Message? = nil
  ) -> Event_Impression {
    var impression = Event_Impression()
    monitor.execute {
      impression.timing = timingMessage()
      impression.impressionID = idMap.impressionID()
      setValue(insertionID, in: &impression.insertionID)
      setValue(requestID, in: &impression.requestID)
      setValue(sessionID, in: &impression.sessionID)
      setValue(viewID ?? self.viewID, in: &impression.viewID)
      setValue(autoViewID, in: &impression.autoViewID)
      setValue(contentID, in: &impression.contentID)
      setValue(sourceType?.protoValue, in: &impression.sourceType)
      setValue(propertiesMessage(properties), in: &impression.properties)
      log(message: impression)
    }
    return impression
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
  ///   - requestID: Request ID as provided by Promoted
  ///   - viewID: View ID to set in impression. If not provided, defaults to
  ///     the view ID last logged via `logView`.
  ///   - properties: Client-specific message
  /// - Returns:
  ///   Logged event message.
  @discardableResult
  func logAction(
    name: String,
    type: ActionType,
    impressionID: String? = nil,
    contentID: String? = nil,
    insertionID: String? = nil,
    requestID: String? = nil,
    viewID: String? = nil,
    autoViewID: String? = nil,
    targetURL: String? = nil,
    elementID: String? = nil,
    properties: Message? = nil
  ) -> Event_Action {
    var action = Event_Action()
    monitor.execute {
      action.timing = timingMessage()
      action.actionID = idMap.actionID()
      setValue(impressionID, in: &action.impressionID)
      setValue(contentID, in: &action.contentID)
      setValue(insertionID, in: &action.insertionID)
      setValue(requestID, in: &action.requestID)
      setValue(sessionID, in: &action.sessionID)
      setValue(viewID ?? self.viewID, in: &action.viewID)
      setValue(autoViewID, in: &action.autoViewID)
      action.name = name
      setValue(type.protoValue, in: &action.actionType)
      action.elementID = elementID ?? name
      switch type {
      case .navigate:
        var navigateAction = Event_NavigateAction()
        setValue(targetURL, in: &navigateAction.targetURL)
        action.navigateAction = navigateAction
      default:
        break
      }
      setValue(propertiesMessage(properties), in: &action.properties)
      log(message: action)
    }
    return action
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
  /// - Returns:
  ///   Logged event message.
  @discardableResult
  internal func logView(
    trackerKey: ViewTracker.Key,
    useCase: UseCase? = nil,
    properties: Message? = nil
  ) -> Event_View? {
    if let state = viewTracker.trackView(key: trackerKey, useCase: useCase) {
      return logView(trackerState: state, properties: properties)
    }
    return nil
  }

  @discardableResult
  private func logView(
    trackerState: ViewTracker.State,
    viewID: String? = nil,
    properties: Message? = nil
  ) -> Event_View {
    return logView(
      name: trackerState.name,
      useCase: trackerState.useCase,
      viewID: viewID,
      properties: properties
    )
  }

  @discardableResult
  internal func logView(
    name: String? = nil,
    useCase: UseCase? = nil,
    viewID: String? = nil,
    properties: Message? = nil
  ) -> Event_View {
    var view = Event_View()
    monitor.execute {
      view.timing = timingMessage()
      needsViewStateCheck = false  // No need for check when logging view.
      setValue(viewID ?? self.viewID, in: &view.viewID)
      setValue(sessionID, in: &view.sessionID)
      setValue(name, in: &view.name)
      setValue(useCase?.protoValue, in: &view.useCase)
      setValue(propertiesMessage(properties), in: &view.properties)
      view.locale = cachedLocaleMessage
      view.viewType = .appScreen
      let appScreenView = Event_AppScreenView()
      // TODO(yu-hong): Fill out AppScreenView.
      view.appScreenView = appScreenView
      log(message: view)
      history?.viewIDDidChange(value: viewID, event: view)
    }
    return view
  }

  @discardableResult
  func logAutoView(
    name: String? = nil,
    useCase: UseCase? = nil,
    autoViewID: String? = nil,
    properties: Message? = nil
  ) -> Event_AutoView {
    var autoView = Event_AutoView()
    monitor.execute {
      autoView.timing = timingMessage()
      setValue(autoViewID, in: &autoView.autoViewID)
      setValue(sessionID, in: &autoView.sessionID)
      setValue(name, in: &autoView.name)
      setValue(useCase?.protoValue, in: &autoView.useCase)
      setValue(propertiesMessage(properties), in: &autoView.properties)
      autoView.locale = cachedLocaleMessage
      let appScreenView = Event_AppScreenView()
      // TODO(yu-hong): Fill out AppScreenView.
      autoView.appScreenView = appScreenView
      log(message: autoView)
      //history?.viewIDDidChange(value: viewID, event: view)
    }
    return autoView
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
    logRequest.device = cachedDeviceMessage
    for event in events {
      switch event {
      case let user as Event_User:
        logRequest.user.append(user)
      case let view as Event_View:
        logRequest.view.append(view)
      case let autoView as Event_AutoView:
        logRequest.autoView.append(autoView)
      case let request as Delivery_Request:
        logRequest.request.append(request)
      case let insertion as Delivery_Insertion:
        logRequest.insertion.append(insertion)
      case let impression as Event_Impression:
        logRequest.impression.append(impression)
      case let action as Event_Action:
        logRequest.action.append(action)
      default:
        osLog?.warning(
          "flush/logRequestMessage: Unknown event: %{private}@",
          String(describing: event)
        )
        monitor.executionDidError(
          MetricsLoggerError.unexpectedEvent(event)
        )
      }
    }
    if config.anyDiagnosticsEnabled {
      var mobileDiagnostics = mobileDiagnosticsMessage()
      if config.diagnosticsIncludeBatchSummaries, let xray = xray {
        fillDiagnostics(in: &mobileDiagnostics, xray: xray)
      }
      if config.diagnosticsIncludeAncestorIDHistory {
        fillAncestorIDHistory(in: &mobileDiagnostics)
      }
      osLog?.debug(
        "diagnostics: %{private}@",
        String(describing: mobileDiagnostics)
      )
      var diagnostics = Event_Diagnostics()
      diagnostics.timing = timingMessage()
      diagnostics.mobileDiagnostics = mobileDiagnostics
      logRequest.diagnostics.append(diagnostics)
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
        let data = try connection.sendMessage(
          request, clientConfig: config
        ) { [weak self] (data, error) in
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
        osLog?.error("flush/response: %{public}@", e.localizedDescription)
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

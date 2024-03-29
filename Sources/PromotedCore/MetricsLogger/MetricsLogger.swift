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

  // Dependencies
  // Properties exposed outside of this file should be idempotent.

  let buildInfo: BuildInfo
  let clock: Clock
  let config: ClientConfig
  let deviceInfo: DeviceInfo
  let idMap: IDMap

  private let connection: NetworkConnection
  private let monitor: OperationMonitor
  private let osLog: OSLog?
  private let store: PersistentStore
  private let xray: Xray?

  // Internal state

  private var logMessages: [Message]
  
  /// Timer for pending batched log request.
  private var batchLoggingTimer: ScheduledTimer?

  /// Used for view state tracking.
  private var needsViewStateCheck: Bool

  private(set) var viewTracker: ViewTracker

  // Ancestor IDs

  /// User ID for this session. Will be updated when
  /// `startSession(userID:)` or `startSessionSignedOut()` is
  /// called.
  private(set) var userID: ID
  
  private(set) lazy var logUserIDProducer: IDProducer = IDProducer(
    initialValueProducer: { [weak self] in
      guard let self = self else { return .null }
      if let savedID = self.store.logUserID {
        return .autogenerated(value: savedID)
      }
      return self.idMap.logUserID()
    },
    nextValueProducer: { [weak self] in self?.idMap.logUserID() ?? .null }
  )

  private(set) lazy var sessionIDProducer: IDProducer = IDProducer(
    producer: { [weak self] in self?.idMap.sessionID() ?? .null }
  )

  var history: AncestorIDHistory?

  // Cached log messages

  var cachedDeviceMessage: Common_Device?
  var cachedLocaleMessage: Common_Locale?
  var cachedClientInfoMessage: Common_ClientInfo?

  typealias Deps = (
    BuildInfoSource &
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
    buildInfo = deps.buildInfo
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

    viewTracker = deps.viewTracker()
    needsViewStateCheck = false

    userID = .null
    history = config.diagnosticsIncludeAncestorIDHistory ?
      AncestorIDHistory(osLog: osLog, xray: xray) : nil

    cachedDeviceMessage = nil
    cachedLocaleMessage = nil
    
    super.init()
    monitor.addOperationMonitorListener(self)
  }

  func withMonitoredExecution(
    needsViewStateCheck: Bool = true,
    _ operation: OperationMonitor.Operation
  ) {
    monitor.execute {
      if !needsViewStateCheck {
        self.needsViewStateCheck = false
      }
      operation()
    }
  }

  func handleLoggingError(
    _ error: MetricsLoggerError,
    function: String = #function
  ) {
    handleError(error, function: function)
  }

  func handleNetworkError(
    _ error: Error,
    function: String = #function
  ) {
    handleError(error, function: function)
  }

  private func handleError(
    _ error: Error,
    function: String
  ) {
    withMonitoredExecution {
      monitor.executionDidError(error, function: function)
    }
  }
}

// MARK: - Ancestor IDs
public extension MetricsLogger {
  /// Log user ID for this session. Updated when
  /// `startSession(userID:)` or `startSessionSignedOut()` is
  /// called.
  var logUserID: String? {
    get { logUserIDProducer.currentValue.stringValue }
    set {
      logUserIDProducer.currentValue = .idForPlatformSpecifiedString(newValue)
      history?.logUserIDDidChange(value: newValue)
    }
  }

  /// Log user ID for this session.
  /// If read before the first call to `startSession*`,
  /// returns the cached ID from the previous session from
  /// `PeristentStore`.
  var currentOrPendingLogUserID: String? {
    logUserIDProducer.currentOrPendingValue.stringValue
  }

  /// Session ID for this session. Updated when
  /// `startSession(userID:)` or `startSessionSignedOut()` is
  /// called.
  var sessionID: String? {
    get { sessionIDProducer.currentValue.stringValue }
    set {
      sessionIDProducer.currentValue = .idForPlatformSpecifiedString(newValue)
      history?.sessionIDDidChange(value: newValue)
    }
  }

  /// Session ID for this session.
  /// If read before the first call to `startSession*`,
  /// returns an ID that will be used for the first session.
  var currentOrPendingSessionID: String? {
    sessionIDProducer.currentOrPendingValue.stringValue
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
      return viewTracker.id.currentValue.stringValue
    }
    set {
      viewTracker.id.currentValue = .idForPlatformSpecifiedString(newValue)
      history?.viewIDDidChange(value: newValue)
    }
  }

  /// View ID for current view.
  /// If read before the first call to `logView()`,
  /// returns an ID that will be used for the first view.
  var currentOrPendingViewID: String? {
    viewTracker.id.currentOrPendingValue.stringValue
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
    let existingUserID = self.userID.stringValue
    if (existingUserID != nil) && (existingUserID == userID) { return }

    self.userID = .idForPlatformSpecifiedString(userID)
    store.userID = userID

    // Reads logUserID from store for initial value, if available.
    store.logUserID = logUserIDProducer.advance().stringValue
  }
}

// MARK: - Event logging base methods
extension MetricsLogger {
  /// Logs a user event.
  ///
  /// Autogenerates the following fields:
  /// - `userInfo` from `userID` and `logUserID`
  /// - `timing` from `clock.nowMillis`
  ///
  /// - Parameters:
  ///   - properties: Client-specific message
  /// - Returns:
  ///   Logged event message.
  @discardableResult
  private func logUser(properties: Message? = nil) -> Event_User? {
    var user = Event_User()
    monitor.execute {
      user.userInfo = userInfoMessage()
      user.timing = timingMessage()
      if let i = identifierProvenancesMessage() {
        user.idProvenances = i
      }
      if let p = propertiesMessage(properties) { user.properties = p }
      log(message: user)
      history?.logUserIDDidChange(value: logUserID, event: user)
      history?.sessionIDDidChange(value: sessionID)
    }
    return user
  }

  // TODO(yuna): These logView methods remain in this file because
  // they modify the internal state of view IDs. These will be obsolete
  // when we implement AutoView/CollectionTracker for iOS and UIKit.

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
  func logView(
    trackerKey: ViewTracker.Key,
    useCase: UseCase? = nil,
    properties: Message? = nil
  ) -> Event_View? {
    if let state = viewTracker.trackView(key: trackerKey, useCase: useCase) {
      return logView(trackerState: state, properties: properties)
    }
    return nil
  }
}

// MARK: - Sending events
public extension MetricsLogger {

  /// Enqueues the given message for logging. Messages are then
  /// delivered to the server on a timer.
  func log(message: Message) {
    guard Thread.isMainThread else {
      handleLoggingError(.calledFromWrongThread)
      return
    }
    logMessages.append(message)
    monitor.executionWillLog(message: message)
    validate(message: message)
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
    logRequest.clientInfo = clientInfoMessage()
    logRequest.userInfo = userInfoMessage()
    logRequest.device = deviceMessage()
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
        handleLoggingError(.unexpectedEvent(event))
      }
    }
    if let diagnostics = diagnosticsMessage(xray: xray) {
      osLog?.debug(
        "diagnostics: %{private}@",
        String(describing: diagnostics)
      )
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
      validate(message: request)
      do {
        let data = try connection.sendMessage(
          request,
          clientConfig: config
        ) { [weak self] (data, error) in
          self?.handleFlushResponse(data: data, error: error)
        }
        monitor.executionWillLog(message: request)
        monitor.executionWillLog(data: data)
      } catch {
        handleNetworkError(error)
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
        handleNetworkError(e)
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

  func startSessionForTesting(userID: String) {
    startSession(userID: userID)
  }

  func startSessionSignedOutForTesting() {
    startSessionSignedOut()
  }

  func logUserForTesting(properties: Message? = nil) {
    logUser(properties: properties)
  }
}

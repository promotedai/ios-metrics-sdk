import Foundation
import SwiftProtobuf

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
  
  /// Log user ID for this session. Updated when
  /// `startSession(userID:)` or `startSessionSignedOut()` is
  /// called. If read before the first call to `startSession*`,
  /// returns the cached ID from the previous session from
  /// `PeristentStore`.
  public var logUserID: String {
    return logUserIDProducer.currentValue
  }
  private let logUserIDProducer: IDProducer
  
  /// Session ID for this session. Updated when
  /// `startSession(userID:)` or `startSessionSignedOut()` is
  /// called. If read before the first call to `startSession*`,
  /// returns an ID that will be used for the first session.
  public var sessionID: String {
    return sessionIDProducer.currentValue
  }
  private let sessionIDProducer: IDProducer
  
  /// View ID for current view. Updated when `logView()` is
  /// called. If read before the first call to `logView()`,
  /// returns an ID that will be used for the first view.
  public var viewID: String {
    return viewTracker.viewID
  }
  let viewTracker: ViewTracker
  
  private let xray: Xray?

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
       store: PersistentStore,
       viewTracker: ViewTracker? = nil,
       xray: Xray?) {
    self.clock = clock
    self.config = clientConfig
    self.connection = connection
    self.deviceInfo = deviceInfo
    self.idMap = idMap
    self.store = store

    self.logMessages = []
    self.userID = nil
    self.logUserIDProducer = IDProducer(initialValueProducer: {
      return store.logUserID ?? idMap.logUserID()
    }, nextValueProducer: {
      return idMap.logUserID()
    })
    self.sessionIDProducer = IDProducer { return idMap.sessionID() }
    self.viewTracker = viewTracker ?? ViewTracker(idMap: idMap)
    self.xray = xray
  }

  // MARK: - Starting new sessions
  /// Call when sign-in completes with specified user ID.
  /// Starts logging session with the provided user and logs a
  /// user event.
  @objc(startSessionAndLogUserWithID:)
  public func startSessionAndLogUser(userID: String) {
    executeInContext(context: .startSession, needsViewStateSync: false) {
      startSession(userID: userID)
      logUser()
      logSession()
    }
  }

  /// Call when sign-in completes with no user.
  /// Starts logging session with signed-out user and logs a
  /// user event.
  @objc public func startSessionAndLogSignedOutUser() {
    executeInContext(context: .startSession, needsViewStateSync: false) {
      startSessionSignedOut()
      logUser()
      logSession()
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
    // Reads logUserID from store for initial value, if available.
    let logUserID = logUserIDProducer.nextValue()

    store.userID = userID
    store.logUserID = logUserID
  }

  // MARK: - Internal methods
  
  private var loggingContextDepth = 0
  
  /// Groups a series of log messages with the same view, session,
  /// and user context. Avoids doing multiple checks for this
  /// context when logging a large number of events.
  func executeInContext(context: Xray.Context, _ block: () -> Void) {
    executeInContext(context: context, needsViewStateSync: true, block)
  }

  /// Ensures that the view ID is correct for the logging that
  /// occurs within the given block. When called re-entrantly,
  /// only the first (outermost) call performs the view state
  /// checking, since that checking is potentially expensive.
  private func executeInContext(context: Xray.Context,
                                needsViewStateSync: Bool,
                                _ block: () -> Void) {
    if loggingContextDepth == 0 {
      if needsViewStateSync {
        ensureViewStateInSync()
      }
      xray?.metricsLoggerCallWillStart(context: context)
    }
    loggingContextDepth += 1
    defer {
      loggingContextDepth -= 1
      if loggingContextDepth == 0 {
        xray?.metricsLoggerCallDidComplete()
      }
    }
    block()
  }
  
  private func ensureViewStateInSync() {
    if let state = viewTracker.updateState() {
      logView(trackerState: state)
    }
  }

  private func userInfoMessage() -> Common_UserInfo {
    var userInfo = Common_UserInfo()
    if let id = userID { userInfo.userID = id }
    userInfo.logUserID = logUserID
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
  /// - `timing` from `clock.nowMillis`
  ///
  /// - Parameters:
  ///   - properties: Client-specific message
  func logUser(properties: Message? = nil) {
    executeInContext(context: .logUser) {
      var user = Event_User()
      user.timing = timingMessage()
      if let p = propertiesMessage(properties) { user.properties = p }
      log(message: user)
    }
  }
  
  /// Logs a session event.
  ///
  /// Autogenerates the following fields:
  /// - `timing` from `clock.nowMillis`
  /// - `sessionID` from state in this logger
  /// - `startEpochMillis` from `clock.nowMillis`
  ///
  /// - Parameters:
  ///   - properties: Client-specific message
  func logSession(properties: Message? = nil) {
    executeInContext(context: .logSession) {
      var session = Event_Session()
      session.timing = timingMessage()
      session.sessionID = sessionID
      session.startEpochMillis = UInt64(clock.nowMillis)
      if let p = propertiesMessage(properties) { session.properties = p }
      log(message: session)
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
    executeInContext(context: .logImpression) {
      let optionalID = idMap.impressionIDOrNil(insertionID: insertionID,
                                               contentID: contentID,
                                               logUserID: logUserID)
      guard let impressionID = optionalID else { return }
      var impression = Event_Impression()
      impression.timing = timingMessage()
      impression.impressionID = impressionID
      if let id = insertionID { impression.insertionID = id }
      if let id = requestID { impression.requestID = id }
      impression.sessionID = sessionID
      impression.viewID = viewID
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
    executeInContext(context: .logAction) {
      var action = Event_Action()
      action.timing = timingMessage()
      action.actionID = idMap.actionID()
      let impressionID = idMap.impressionIDOrNil(insertionID: insertionID,
                                                 contentID: contentID,
                                                 logUserID: logUserID)
      if let id = impressionID { action.impressionID = id }
      if let id = insertionID { action.insertionID = id }
      if let id = requestID { action.requestID = id }
      action.sessionID = sessionID
      action.viewID = viewID
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
    executeInContext(context: .logView, needsViewStateSync: false) {
      var view = Event_View()
      view.timing = timingMessage()
      view.viewID = trackerState.viewID
      view.sessionID = sessionID
      view.name = trackerState.name
      if let use = trackerState.useCase?.protoValue { view.useCase = use }
      if let p = propertiesMessage(properties) { view.properties = p }
      view.device = deviceMessage
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
    assert(Thread.isMainThread,
           "[MetricsLogger] Logging must be done on main thread")
    logMessages.append(message)
    xray?.metricsLoggerCallDidLog(message: message)
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
    xray?.metricsLoggerBatchWillStart()
    defer { xray?.metricsLoggerBatchDidComplete() }
    cancelPendingBatchLoggingFlush()
    if logMessages.isEmpty { return }
    if !config.loggingEnabled { return }

    let eventsCopy = logMessages
    logMessages.removeAll()
    let request = logRequestMessage(events: eventsCopy)
    xray?.metricsLoggerBatchWillSend(message: request)
    do {
      try connection.sendMessage(request, clientConfig: config) {
        [weak self] (data, error) in
        print("[MetricsLogger] Logging finished.")
        guard let xray = self?.xray else { return }
        guard let batch = xray.networkBatches.last else { return }
        if let e = error  {
          xray.metricsLoggerBatchResponseDidError(e)
          return
        }
        xray.metricsLoggerBatchResponseDidComplete()
        print("[MetricsLogger] Spent \(batch.timeSpentAcrossCalls) ms " +
              "for \(batch.messageSizeBytes) bytes.")
        print("[MetricsLogger] TOTAL \(xray.totalTimeSpent) ms " +
              "for \(xray.totalBytesSent) bytes.")
      }
    } catch {
      xray?.metricsLoggerBatchDidError(error)
    }
  }
}

// MARK: - Testing
extension MetricsLogger {
  var logMessagesForTesting: [Message] { return logMessages }
  var userIDForTesting: String? { return userID }
  
  func startSessionForTesting(userID: String) {
    startSession(userID: userID)
  }
  
  func startSessionSignedOutForTesting() {
    startSessionSignedOut()
  }
}

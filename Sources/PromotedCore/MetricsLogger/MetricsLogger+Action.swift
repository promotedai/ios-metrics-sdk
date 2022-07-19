import Foundation
import SwiftProtobuf
import UIKit

// MARK: - Navigate Action Logging Methods (ObjC)

public extension MetricsLogger {

  /// Logs a navigate action for given content.
  @objc(logNavigateActionWithContent:)
  func _objcLogNavigateAction(content: Content) {
    logNavigateAction(content: content)
  }
}

// MARK: - Navigate Action Logging Methods (Swift)

public extension MetricsLogger {

  /// Logs a navigate action for given content.
  /// Optionally includes destination screen/UIViewController.
  @discardableResult
  func logNavigateAction(
    content: Content,
    screenName: String? = nil,
    viewController: UIViewController? = nil,
    autoViewState: AutoViewState = .empty
  ) -> Event_Action {
    return logAction(
      type: .navigate,
      name: (
        screenName
          ?? viewController?.promotedViewLoggingName
          ?? ActionType.navigate.description
      ),
      autoViewState: autoViewState,
      contentID: content.contentID,
      insertionID: content.insertionID
    )
  }
}

// MARK: - Action Logging Methods (ObjC)

public extension MetricsLogger {

  /// Logs an action with given type and content.
  @objc(logActionWithType:content:)
  func _objcLogAction(type: ActionType, content: Content?) {
    logAction(
      type: type,
      name: type.description,
      contentID: content?.contentID,
      insertionID: content?.insertionID
    )
  }
  
  /// Logs an action with given type, content, and name.
  @objc(logActionWithType:content:name:)
  func _objcLogAction(type: ActionType, content: Content?, name: String?) {
    logAction(
      type: type,
      name: name ?? type.description,
      contentID: content?.contentID,
      insertionID: content?.insertionID
    )
  }
}

// MARK: - Action Logging Methods (Swift)

public extension MetricsLogger {

  /// Logs an action with given type, content, and name.
  @discardableResult
  func logAction(
    type: ActionType,
    content: Content?,
    name: String? = nil,
    autoViewState: AutoViewState = .empty,
    collectionInteraction: CollectionInteraction? = nil,
    impressionID: String? = nil,
    viewID: String? = nil
  ) -> Event_Action {
    return logAction(
      type: type,
      name: name ?? type.description,
      autoViewState: autoViewState,
      collectionInteraction: collectionInteraction,
      contentID: content?.contentID,
      impressionID: impressionID,
      insertionID: content?.insertionID,
      viewID: viewID
    )
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
  ///
  /// - Parameters:
  ///   - type: Semantic meaning of action
  ///   - name: Name for action to log, human readable
  ///   - targetURL: URL of navigation, designed for web SDK
  ///   - elementID: Element that triggered action, designed for web SDK.
  ///     If no `elementID` is provided, is derived from `name`
  ///   - autoViewState: Auto view to associate with action
  ///   - collectionInteraction: Additional information about UI interaction.
  ///   - contentID: Content ID for marketplace content
  ///   - impressionID: Impression ID to associate with action as provided
  ///     by mobile SDK
  ///   - insertionID: Insertion ID as provided by Promoted
  ///   - requestID: Request ID as provided by Promoted
  ///   - viewID: View ID to set in impression. If not provided, defaults
  ///     to the view ID last logged via `logView`.
  ///   - properties: Client-specific message
  /// - Returns:
  ///   Logged event message.
  @discardableResult
  func logAction(
    type: ActionType,
    name: String,
    targetURL: String? = nil,
    elementID: String? = nil,
    autoViewState: AutoViewState = .empty,
    collectionInteraction: CollectionInteraction? = nil,
    contentID: String? = nil,
    impressionID: String? = nil,
    insertionID: String? = nil,
    requestID: String? = nil,
    viewID: String? = nil,
    properties: Message? = nil
  ) -> Event_Action {
    var action = Event_Action()
    withMonitoredExecution {
      action.timing = timingMessage()
      let actionID = idMap.actionID()
      if let id = actionID.stringValue { action.actionID = id }
      if let i = impressionID { action.impressionID = i }
      if let c = contentID { action.contentID = c }
      if let i = insertionID { action.insertionID = i }
      if let r = requestID { action.requestID = r }
      if let s = sessionID { action.sessionID = s }
      if let v = viewID ?? self.viewID { action.viewID = v }
      if let a = autoViewState.autoViewID { action.autoViewID = a }
      action.name = name
      action.actionType = type.protoValue
      action.elementID = elementID ?? name
      switch type {
      case .navigate:
        var navigateAction = Event_NavigateAction()
        if let t = targetURL { navigateAction.targetURL = t }
        action.navigateAction = navigateAction
      case .custom:
        action.customActionType = name
      default:
        break
      }
      if let h = autoViewState.hasSuperimposedViews {
        action.hasSuperimposedViews_p = h
      }
      if let c = clientPositionMessage(collectionInteraction) {
        action.clientPosition = c
      }
      if let i = identifierProvenancesMessage(
        autoViewID: autoViewState.autoViewID,
        impressionID: .idForAutogeneratedString(impressionID),
        actionID: actionID,
        contentID: contentID,
        insertionID: insertionID,
        requestID: requestID,
        platformSpecifiedViewID: viewID,
        internalViewID: viewTracker.id.currentValue
      ) {
        action.idProvenances = i
      }
      if let p = propertiesMessage(properties) { action.properties = p }
      log(message: action)
    }
    return action
  }
}

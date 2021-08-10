import Foundation
import UIKit

// MARK: - Impression logging helper methods (ObjC)
public extension MetricsLogger {
  /// Logs an impression for the given content.
  /// See also `ImpressionTracker` and `ScrollTracker` for more
  /// advanced impression tracking methods.
  @objc(logImpressionWithContent:)
  func _objcLogImpression(content: Content) {
    logImpression(content: content, sourceType: .unknown)
  }

  /// Logs an impression for the given content and source type.
  /// See also `ImpressionTracker` and `ScrollTracker` for more
  /// advanced impression tracking methods.
  @objc(logImpressionWithContent:sourceType:)
  func _objcLogImpression(
    content: Content,
    sourceType: ImpressionSourceType
  ) {
    logImpression(content: content, sourceType: sourceType)
  }
}

// MARK: - Impression logging helper methods (Swift)
public extension MetricsLogger {
  /// Logs an impression for the given content and source type.
  /// See also `ImpressionTracker` and `ScrollTracker` for more
  /// advanced impression tracking methods.
  @discardableResult
  func logImpression(
    content: Content,
    sourceType: ImpressionSourceType = .unknown
  ) -> Event_Impression {
    return logImpression(
      contentID: content.contentID,
      insertionID: content.insertionID,
      sourceType: sourceType
    )
  }
}

// MARK: - Navigate action logging helper methods (ObjC)
public extension MetricsLogger {
  /// Logs a navigate action for given content.
  @objc(logNavigateActionWithContent:)
  func _objcLogNavigateAction(content: Content) {
    logNavigateAction(content: content)
  }
}

// MARK: - Navigate action logging helper methods (Swift)
public extension MetricsLogger {
  /// Logs a navigate action for given content.
  /// Optionally includes destination screen/UIViewController.
  @discardableResult
  func logNavigateAction(
    content: Content,
    screenName: String? = nil,
    viewController: UIViewController? = nil
  ) -> Event_Action {
    return logAction(
      name: screenName ?? viewController?.promotedViewLoggingName,
      type: .navigate,
      contentID: content?.contentID,
      insertionID: content?.insertionID
    )
  }
}

// MARK: - Action logging helper methods (ObjC)
public extension MetricsLogger {
  /// Logs an action with given type and content.
  @objc(logActionWithType:content:)
  func _objcLogAction(type: ActionType, content: Content?) {
    logAction(
      name: nil,
      type: type,
      contentID: content?.contentID,
      insertionID: content?.insertionID
    )
  }
  
  /// Logs an action with given type, content, and name.
  @objc(logActionWithType:content:name:)
  func _objcLogAction(type: ActionType, content: Content?, name: String?) {
    logAction(
      name: name,
      type: type,
      contentID: content.contentID,
      insertionID: content.insertionID
    )
  }
}

// MARK: - Action logging helper methods (Swift)
public extension MetricsLogger {
  /// Logs an action with given type, content, and name.
  @discardableResult
  func logAction(
    type: ActionType,
    content: Content?,
    name: String? = nil
  ) -> Event_Action {
    return logAction(
      name: name,
      type: type,
      contentID: content?.contentID,
      insertionID: content?.insertionID
    )
  }
}

// MARK: - View logging helper methods
public extension MetricsLogger {
  /// Logs a view of the given `UIViewController`.
  @objc func logView(viewController: UIViewController) {
    logView(trackerKey: .uiKit(viewController: viewController))
  }
  
  /// Logs a view of the given `UIViewController` and use case.
  @objc func logView(viewController: UIViewController,
                     useCase: UseCase) {
    logView(trackerKey: .uiKit(viewController: viewController), useCase: useCase)
  }

  /// Logs a view with the given route name and key (React Native).
  func logViewReady(routeName: String, routeKey: String, useCase: UseCase? = nil) {
    viewTracker.reset()
    logView(trackerKey: .reactNative(routeName: routeName, routeKey: routeKey),
            useCase: useCase)
  }
  
  /// Logs a view with the given route name and key (React Native).
  func logViewChange(routeName: String, routeKey: String, useCase: UseCase? = nil) {
    logView(trackerKey: .reactNative(routeName: routeName, routeKey: routeKey),
            useCase: useCase)
  }
}

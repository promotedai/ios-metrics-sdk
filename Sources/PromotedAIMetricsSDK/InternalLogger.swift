import Foundation
import SwiftProtobuf

/// `UIViewController` if `UIKit` is supported on build platform,
/// `AnyObject` otherwise. Allows us to unit test on macOS.
#if canImport(UIKit)
import UIKit
public typealias ViewControllerType = UIViewController
#else
public typealias ViewControllerType = AnyObject
#endif

/** Common protocol between `MetricsLogger` and React Native module. */
@objc public protocol InternalLogger {

  // MARK: - Starting new sessions
  /// Call when sign-in completes with specified user ID.
  /// Starts logging session with the provided user and logs a
  /// user event.
  @objc(startSessionAndLogUserWithID:)
  func startSessionAndLogUser(userID: String)

  /// Call when sign-in completes with no user.
  /// Starts logging session with signed-out user and logs a
  /// user event.
  @objc func startSessionAndLogSignedOutUser()
  
  // MARK: - Impressions
  /// Logs an impression for the given item.
  @objc func logImpression(item: Item)

  // MARK: - Clicks
  /// Logs a click to like/unlike the given item.
  @objc(logClickToLikeItem:didLike:)
  func logClickToLike(item: Item, didLike: Bool)

  /// Logs a click to show the given view controller.
  @objc(logClickToShowViewController:)
  func logClickToShow(viewController: ViewControllerType)
  
  /// Logs a click to show the given view controller for given item.
  @objc(logClickToShowViewController:forItem:)
  func logClickToShow(viewController: ViewControllerType, forItem item: Item)
  
  /// Logs a click to show a screen with given name.
  @objc(logClickToShowScreenName:)
  func logClickToShow(screenName: String)
  
  /// Logs a click to show a screen with given name for given item.
  @objc(logClickToShowScreenName:forItem:)
  func logClickToShow(screenName: String, forItem item: Item)
  
  /// Logs a click to sign up as a new user.
  @objc func logClickToSignUp(userID: String)
  
  /// Logs a click to purchase the given item.
  @objc(logClickToPurchaseItem:)
  func logClickToPurchase(item: Item)

  /// Logs a click for the given action name.
  @objc func logClick(actionName: String)

  /// Logs a click for the given action name involving the given item.
  @objc func logClick(actionName: String, item: Item)
  
  // MARK: - Views
  /// Logs a view of the given view controller.
  @objc func logView(viewController: ViewControllerType)
  
  /// Logs a view of the given view controller and use case.
  @objc func logView(viewController: ViewControllerType,
                     useCase: UseCase)

  /// Logs a view of a screen with the given name.
  @objc func logView(screenName: String)
  
  /// Logs a view of a screen with the given name and use case.
  @objc func logView(screenName: String, useCase: UseCase)
}

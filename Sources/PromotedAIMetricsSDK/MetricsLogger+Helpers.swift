import Foundation

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
    logAction(name: actionName,
              type: .like,
              contentID: content.contentID,
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
    logAction(name: name,
              type: .click,
              contentID: content?.contentID,
              insertionID: content?.insertionID)
  }
  
  /// Logs a click to sign up as a new user.
  @objc func logClickToSignUp(userID: String) {
    logAction(name: "sign-up",
              type: .click,
              contentID: userID,
              insertionID: nil)
  }
  
  /// Logs a click to purchase the given item.
  @objc(logClickToPurchaseItem:)
  func logClickToPurchase(item: Item) {
    logAction(name: "purchase",
              type: .purchase,
              contentID: item.contentID,
              insertionID: item.insertionID)
  }
  
  /// Logs a click for the given action name.
  @objc func logClick(actionName: String) {
    logAction(name: actionName,
              type: .click,
              contentID: nil,
              insertionID: nil)
  }
  
  /// Logs a click for the given action name involving the given item.
  @objc func logClick(actionName: String, content: Content) {
    logAction(name: actionName,
              type: .click,
              contentID: content.contentID,
              insertionID: content.insertionID)
  }

  // MARK: - View logging helper methods
  /// Logs a view of the given `UIViewController`.
  @objc func logView(viewController: ViewControllerType) {
    let name = loggingNameFor(viewController: viewController)
    self.logView(name: name, useCase: nil)
  }
  
  /// Logs a view of the given `UIViewController` and use case.
  @objc func logView(viewController: ViewControllerType,
                     useCase: UseCase) {
    let name = loggingNameFor(viewController: viewController)
    self.logView(name: name, useCase: useCase.protoValue)
  }

  /// Logs a view of a screen with the given name (React Native).
  @objc func logView(screenName: String) {
    self.logView(name: screenName, useCase: nil)
  }
  
  /// Logs a view of a screen with the given name (React Native)
  /// and use case.
  @objc func logView(screenName: String, useCase: UseCase) {
    self.logView(name: screenName, useCase: useCase.protoValue)
  }
}

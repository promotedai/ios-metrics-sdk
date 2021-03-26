import Foundation

public extension MetricsLogger {
  // MARK: - Impression logging helper methods
  /// Logs an impression for the given content.
  @objc func logImpression(content: Content) {
    if let id = content.contentID { logImpression(contentID: id) }
  }

  // MARK: - Click logging helper methods
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
  
  /// Logs an action to purchase the given item.
  @objc func logPurchaseAction(item: Item) {
    logAction(name: "purchase",
              type: .purchase,
              contentID: item.contentID,
              insertionID: item.insertionID)
  }

  /// Logs an action to add the given item to cart.
  @objc func logAddToCartAction(item: Item) {
    logAction(name: "add-to-cart",
              type: .addToCart,
              contentID: item.contentID,
              insertionID: item.insertionID)
  }

  /// Logs an action to share the given content.
  @objc func logShareAction(content: Content) {
    logAction(name: "share",
              type: .share,
              contentID: content.contentID,
              insertionID: content.insertionID)
  }
  
  /// Logs an action to like/unlike the given content.
  @objc func logLikeAction(content: Content, didLike: Bool) {
    let actionName = didLike ? "like" : "unlike"
    logAction(name: actionName,
              type: .like,
              contentID: content.contentID,
              insertionID: content.insertionID)
  }

  /// Logs an action to comment on the given content.
  @objc func logCommentAction(content: Content) {
    logAction(name: "comment",
              type: .comment,
              contentID: content.contentID,
              insertionID: content.insertionID)
  }

  /// Logs an action with given name.
  @objc func logAction(name: String) {
    logAction(name: name,
              type: .click,
              contentID: nil,
              insertionID: nil)
  }
  
  /// Logs an action with given name.
  @objc func logAction(name: String, type: ActionType) {
    logAction(name: name,
              type: type,
              contentID: nil,
              insertionID: nil)
  }
  
  /// Logs an action with given name involving the given content.
  @objc func logAction(name: String, type: ActionType, content: Content) {
    logAction(name: name,
              type: type,
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

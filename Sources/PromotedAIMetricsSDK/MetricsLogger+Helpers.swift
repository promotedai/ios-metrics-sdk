import Foundation

public extension MetricsLogger {
  // MARK: - Impression logging helper methods
  /// Logs an impression for the given content.
  @objc func logImpression(content: Content) {
    if let id = content.contentID { logImpression(contentID: id) }
  }

  // MARK: - Click logging helper methods
  /// Logs a click to show the given view controller.
  @objc func logNavigateAction(viewController: ViewControllerType) {
    logNavigateAction(name: loggingNameFor(viewController: viewController),
                      optionalContent: nil)
  }

  /// Logs a click to show the given view controller.
  @objc func logNavigateAction(viewController: ViewControllerType,
                               forContent content: Content) {
    logNavigateAction(name: loggingNameFor(viewController: viewController),
                      optionalContent: content)
  }
  
  /// Logs a click to show a screen with given name.
  @objc func logNavigateAction(screenName: String) {
    logNavigateAction(name: screenName, optionalContent: nil)
  }
  
  /// Logs a click to show a screen with given name for given item.
  @objc func logNavigateAction(screenName: String, forContent content: Content) {
    logNavigateAction(name: screenName, optionalContent: content)
  }

  private func logNavigateAction(name: String, optionalContent content: Content?) {
    logAction(name: name,
              type: .navigate,
              contentID: content?.contentID,
              insertionID: content?.insertionID)
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

  /// Logs an action with given name and type `.custom`.
  @objc func logAction(name: String) {
    logAction(name: name,
              type: .custom,
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
  
  /// Logs an action with given name, type, and content.
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
    self.logView(name: name, useCase: useCase)
  }

  /// Logs a view of a screen with the given name (React Native).
  @objc func logView(screenName: String) {
    self.logView(name: screenName, useCase: nil)
  }
  
  /// Logs a view of a screen with the given name (React Native)
  /// and use case.
  @objc func logView(screenName: String, useCase: UseCase) {
    self.logView(name: screenName, useCase: useCase)
  }
}

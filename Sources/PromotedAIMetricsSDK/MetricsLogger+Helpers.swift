import Foundation

public extension MetricsLogger {
  // MARK: - Impression logging helper methods
  /// Logs an impression for the given content.
  @objc func logImpression(content: Content) {
    logImpression(contentID: content.contentID, insertionID: content.insertionID)
  }

  // MARK: - Action logging helper methods
  /// Logs a navigate action to the given view controller.
  @objc func logNavigateAction(viewController: ViewControllerType) {
    logNavigateAction(name: LoggingNameFor(viewController: viewController),
                      optionalContent: nil)
  }

  /// Logs a navigate action to the given view controller for given content.
  @objc func logNavigateAction(viewController: ViewControllerType,
                               forContent content: Content) {
    logNavigateAction(name: LoggingNameFor(viewController: viewController),
                      optionalContent: content)
  }
  
  /// Logs a navigate action to a screen with given name.
  @objc func logNavigateAction(screenName: String) {
    logNavigateAction(name: screenName, optionalContent: nil)
  }
  
  /// Logs a navigate action to a screen with given name for given content.
  @objc func logNavigateAction(screenName: String, forContent content: Content) {
    logNavigateAction(name: screenName, optionalContent: content)
  }

  private func logNavigateAction(name: String, optionalContent content: Content?) {
    logAction(name: name,
              type: .navigate,
              contentID: content?.contentID,
              insertionID: content?.insertionID)
  }

  /// Logs an action to add the given item to cart.
  @objc func logAddToCartAction(item: Item) {
    logAction(name: "add-to-cart",
              type: .addToCart,
              contentID: item.contentID,
              insertionID: item.insertionID)
  }

  /// Logs an action to remove the given item from cart.
  @objc func logRemoveFromCartAction(item: Item) {
    logAction(name: "remove-from-cart",
              type: .removeFromCart,
              contentID: item.contentID,
              insertionID: item.insertionID)
  }
    
  /// Logs an action to check out the cart.
  @objc func logCheckoutAction() {
    logAction(name: "checkout",
              type: .checkout,
              contentID: nil,
              insertionID: nil)
  }


  /// Logs an action to purchase the given item.
  @objc func logPurchaseAction(item: Item) {
    logAction(name: "purchase",
              type: .purchase,
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
  
  /// Logs an action to like the given content.
  @objc func logLikeAction(content: Content) {
    logAction(name: "like",
              type: .like,
              contentID: content.contentID,
              insertionID: content.insertionID)
  }

  /// Logs an action to unlike the given content.
  @objc func logUnlikeAction(content: Content) {
    logAction(name: "unlike",
              type: .unlike,
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

  /// Logs an action to make an offer on the given item.
  @objc func logMakeOfferAction(item: Item) {
    logAction(name: "make-offer",
              type: .makeOffer,
              contentID: item.contentID,
              insertionID: item.insertionID)
  }

  /// Logs an action to ask a question about the given content.
  @objc func logAskQuestionAction(content: Content) {
    logAction(name: "ask-question",
              type: .askQuestion,
              contentID: content.contentID,
              insertionID: content.insertionID)
  }

  /// Logs an action to answer a question about the given content.
  @objc func logAnswerQuestionAction(content: Content) {
    logAction(name: "answer-question",
              type: .answerQuestion,
              contentID: content.contentID,
              insertionID: content.insertionID)
  }

  /// Logs an action to sign in to an account.
  @objc func logCompleteSignInAction() {
    logAction(name: "sign-in",
              type: .completeSignIn,
              contentID: nil,
              insertionID: nil)
  }

  /// Logs an action to sign up for an account.
  @objc func logCompleteSignUpAction() {
    logAction(name: "sign-up",
              type: .completeSignUp,
              contentID: nil,
              insertionID: nil)
  }

  /// Logs an action with given name and type `.customActionType`.
  @objc func logAction(name: String) {
    logAction(name: name,
              type: .customActionType,
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
    self.logView(trackerKey: .uiKit(viewController: viewController))
  }
  
  /// Logs a view of the given `UIViewController` and use case.
  @objc func logView(viewController: ViewControllerType,
                     useCase: UseCase) {
    self.logView(trackerKey: .uiKit(viewController: viewController), useCase: useCase)
  }

  /// Logs a view of a screen with the given name (React Native).
  @objc func logView(screenName: String, key: String) {
    self.logView(trackerKey: .reactNative(name: screenName, key: key))
  }
  
  /// Logs a view of a screen with the given name (React Native)
  /// and use case.
  @objc func logView(screenName: String, key: String, useCase: UseCase) {
    self.logView(trackerKey: .reactNative(name: screenName, key: key), useCase: useCase)
  }
}

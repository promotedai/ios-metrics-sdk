import Foundation

/** Type for user actions. */
@objc(PROActionType)
public enum ActionType: Int {
  case unknownActionType // = 0

  /// Action that doesn't correspond to any of the below.
  case customActionType // = 1

  /// Navigating to details about content.
  case navigate // = 2

  /// Adding an item to shopping cart.
  case addToCart // = 4

  /// Remove an item from shopping cart.
  case removeFromCart // = 10

  /// Going to checkout.
  case checkout // = 8

  /// Purchasing an item.
  case purchase // = 3

  /// Sharing content.
  case share // = 5

  /// Liking content.
  case like // = 6

  /// Un-liking content.
  case unlike // = 9

  /// Commenting on content.
  case comment // = 7

  /// Making an offer on content.
  case makeOffer // = 11

  /// Asking a question about content.
  case askQuestion // = 12

  /// Answering a question about content.
  case answerQuestion // = 13

  /// Complete sign-in.
  /// No content_id needed.  If set, set it to the Content's ID (not User).
  case completeSignIn // = 14

  /// Complete sign-up.
  /// No content_id needed.  If set, set it to the Content's ID (not User).
  case completeSignUp // = 15

  public init?(rawValue: Int) {
    switch rawValue {
    case 0: self = .unknownActionType
    case 1: self = .customActionType
    case 2: self = .navigate
    case 3: self = .purchase
    case 4: self = .addToCart
    case 5: self = .share
    case 6: self = .like
    case 7: self = .comment
    case 8: self = .checkout
    case 9: self = .unlike
    case 10: self = .removeFromCart
    case 11: self = .makeOffer
    case 12: self = .askQuestion
    case 13: self = .answerQuestion
    case 14: self = .completeSignIn
    case 15: self = .completeSignUp
    default: self = .unknownActionType
    }
  }

  public var rawValue: Int {
    switch self {
    case .unknownActionType: return 0
    case .customActionType: return 1
    case .navigate: return 2
    case .purchase: return 3
    case .addToCart: return 4
    case .share: return 5
    case .like: return 6
    case .comment: return 7
    case .checkout: return 8
    case .unlike: return 9
    case .removeFromCart: return 10
    case .makeOffer: return 11
    case .askQuestion: return 12
    case .answerQuestion: return 13
    case .completeSignIn: return 14
    case .completeSignUp: return 15
    default: return 0
    }
  }

  var protoValue: Event_ActionType? {
    return Event_ActionType(rawValue: self.rawValue)
  }
}

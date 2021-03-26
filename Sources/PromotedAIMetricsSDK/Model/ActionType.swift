import Foundation

/** Type for user actions. */
@objc(PROActionType)
public enum ActionType: Int {
  case unknown = 0
  case custom = 1
  case click = 2
  case purchase = 3
  case addToCart = 4
  case share = 5
  case like = 6
  case comment = 7
  
  var protoValue: Event_ActionType? {
    return Event_ActionType(rawValue: self.rawValue)
  }
}

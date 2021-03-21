import Foundation

/** Use case for views. */
@objc(PROUseCase)
public enum UseCase: Int {
  case search = 2
  case searchSuggestions = 3
  case feed = 4
  case relatedContent = 5
  case closeUp = 6
  case categoryContent = 7
  case myContent = 8
  case savedContent = 9
  case sellerContent = 10
  
  var protoValue: Event_UseCase? {
    return Event_UseCase(rawValue: self.rawValue)
  }
}

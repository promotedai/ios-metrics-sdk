import Foundation

/** Use case for views. */
@objc(PROUseCase)
public enum UseCase: Int {
  case unknown = 0
  case custom = 1
  case search = 2
  case searchSuggestions = 3
  case feed = 4
  case relatedContent = 5
  case closeUp = 6
  case categoryContent = 7
  case myContent = 8
  case savedContent = 9
  case sellerContent = 10
}

extension UseCase {
  var protoValue: Delivery_UseCase? {
    Delivery_UseCase(rawValue: self.rawValue)
  }
}

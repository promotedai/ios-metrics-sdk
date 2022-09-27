import Foundation

public enum ModerationScope: Int {
  case global = 0
  case currentSearch = 1

  var description: String { description() }

  func description(scopeFilter: String? = nil) -> String {
    switch self {
    case .global:
      return "Global (All Queries)"
    case .currentSearch:
      if let s = scopeFilter {
        return "Current Search: \(s)"
      }
      return "Current Search"
    }
  }

  var detailedDescription: String {
    switch self {
    case .global:
      return "Applies to all Promoted Delivery requests that involve this item."
    case .currentSearch:
      return "Applies to Promoted Delivery requests matching the current request scope that involve this item."
    }
  }
}

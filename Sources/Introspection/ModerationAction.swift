import Foundation

public enum ModerationAction: Int {
  case shadowban = 0
  case sendToReview = 1
  case changeRank = 2

  var description: String { description() }

  func description(rankChangePercent: Int? = nil) -> String {
    switch self {
    case .shadowban:
      return "Shadowbaned by ayates@promoted.ai"
    case .sendToReview:
      return "Sent to review by ayates@promoted.ai"
    case .changeRank:
      if let r = rankChangePercent {
        return "Rank changed \(r < 0 ? "–" : "+")\(abs(r))% by ayates@promoted.ai"
      } else {
        return "Rank changed by ayates@promoted.ai"
      }
    }
  }
  
  var detailedDescription: String {
    switch self {
    case .shadowban:
      return "Prevents this item from showing up in listings. Takes effect immediately."
    case .sendToReview:
      return "Flags this item for manual review. Does not immediately change Delivery behavior."
    case .changeRank:
      return "Changes the rank for this item. Takes effect immediately."
    }
  }
}

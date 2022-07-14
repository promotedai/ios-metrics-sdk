import Foundation

/** Types of logging anomalies that we've seen in production. */
enum AnomalyType: Int {
  case missingLogUserIDInUserMessage = 101
  case missingLogUserIDInLogRequest = 102
  case missingJoinableFieldsInImpression = 103
  case missingJoinableFieldsInAction = 104
}

extension AnomalyType: CustomDebugStringConvertible {
  var debugDescription: String {
    switch self {
    case .missingLogUserIDInUserMessage, .missingLogUserIDInLogRequest:
      return """
      An event was logged with no log user ID. This may be due to a recent change in Promoted initialization. Examples include changes to your AppDelegate class, or calls to the Promoted SDK method startSessionAndLogUser().
      """
    case .missingJoinableFieldsInImpression:
      return """
      An impression was logged with no content ID or insertion ID. This may be due to a recent change to a list/collection view, or the data model that powers this view.
      """
    case .missingJoinableFieldsInAction:
      return """
      An action was logged with no impression ID, content ID, or insertion ID. This may be due to a recent change to a list/collection view, or the data model that powers this view.
      """
    }
  }
}

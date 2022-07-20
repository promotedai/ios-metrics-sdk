import Foundation

/** Types of logging anomalies that we've seen in production. */
enum AnomalyType: Int {
  /// Results from a logging call.
  case missingLogUserIDInUserMessage = 101
  /// Results from a logging call.
  case missingLogUserIDInLogRequest = 102
  /// Results from a logging call.
  case missingJoinableFieldsInImpression = 103
  /// Results from a logging call.
  case missingJoinableFieldsInAction = 104
  /// Detected in ReactNativeMetrics when initialization did not occur properly.
  case reactNativeMetricsModuleNotInitialized = 105
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
    case .reactNativeMetricsModuleNotInitialized:
      return """
      PromotedMetricsModule was not initialized correctly. This may be due to a recent change to AppDelegate. Make sure that PromotedMetricsModule is included in -extraModulesForBridge:.
      """
    }
  }
}

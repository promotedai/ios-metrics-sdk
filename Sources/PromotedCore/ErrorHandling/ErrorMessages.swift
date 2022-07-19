#if DEBUG
import Foundation

public protocol ErrorDetails {
  var details: String { get }
}

public extension ClientConfigError: ErrorDetails {
  var details: String {
    return "foo"
  }
}

public extension ModuleConfigError: ErrorDetails {
  var details: String {
    return "foo"
  }
}

public extension MetricsLoggerError: ErrorDetails {
  var details: String {
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
    default:
      return "foo"
    }
  }
}

public extension RemoteConfigConnectionError: ErrorDetails {
  var details: String {
    return "foo"
  }
}
#endif

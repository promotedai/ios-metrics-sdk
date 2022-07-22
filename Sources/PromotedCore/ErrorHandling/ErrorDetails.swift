#if DEBUG
import Foundation

public protocol ErrorDetails {
  var details: String { get }
}

// MARK: - ClientConfigError
extension ClientConfigError: ErrorDetails {
  public var details: String {
    switch self {
    case .invalidURL(let url):
      return """
      An invalid URL was supplied for `ClientConfig.metricsLoggingURL`:
      \(url)
      """
    case .missingAPIKey:
      return """
      No API key was provided via `ClientConfig.metricsLoggingAPIKey`.
      """
    case .missingDevAPIKey:
      return """
      You specified `ClientConfig.devMetricsLoggingURL` but not `ClientConfig.devMetricsLoggingAPIKey`.
      """
    case .invalidMetricsLoggingWireFormat:
      return """
      Invalid value for enum `ClientConfig.metricsLoggingWireFormat`.
      """
    case .invalidXrayLevel:
      return """
      Invalid value for enum `ClientConfig.xrayLevel`.
      """
    case .invalidOSLogLevel:
      return """
      Invalid value for enum `ClientConfig.osLogLevel`.
      """
    case .invalidDiagnosticsSamplingEndDateString(let s):
      return """
      You indicated an end date for diagnostic sampling that does not appear to be in the format yyyy-MM-dd:

      \(s)
      """
    case .invalidMetricsLoggingErrorHandling:
      return """
      Invalid value for enum `ClientConfig.metricsLoggingErrorHandling`.
      """
    }
  }
}

// MARK: - ModuleConfigError
extension ModuleConfigError: ErrorDetails {
  public var details: String {
    switch self {
    case .missingNetworkConnection:
      return """
      Network connection not specified. You are using  `ModuleConfig.coreConfig()`, which requires a custom network connection. Did you mean to use `ModuleConfig.defaultConfig()`?
      """
    }
  }
}

// MARK: - MetricsLoggerError
extension MetricsLoggerError: ErrorDetails {
  static let internalErrorDetails = """
  An internal error occurred in the Promoted SDK. Please email bugs@promoted.ai and provide the error code.
  """
  public var details: String {
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
    case .propertiesSerializationError(_),
         .calledFromWrongThread,
         .unexpectedEvent(_):
      return Self.internalErrorDetails
    }
  }
}

// MARK: - ClientConfigFetchError
extension ClientConfigFetchError: ErrorDetails {
  public var details: String {
    switch self {
    case .networkError(let error):
      return """
      A network error occurred fetching remote config:

      \(error.localizedDescription)

      Please check your Remote Config setup. In a production build, the Promoted SDK will start up and run normally, but Remote Config will not be available.
      """
    case .emptyConfig:
      return """
      Remote Config returned an empty configuration. Please check your Remote Config setup. In a production build, the Promoted SDK will start up and run normally, but Remote Config will not be available.
      """
    case .localCacheEncodeError(let error):
      return """
      An error occured when writing Remote Config to local cache:

      \(error.localizedDescription)

      Please check your Remote Config setup. In a production build, the Promoted SDK will start up and run normally, but Remote Config will not be available.
      """
    }
  }
}

// MARK: - RemoteConfigConnectionError
extension RemoteConfigConnectionError: ErrorDetails {
  public var details: String {
    switch self {
    case .failed(let maybeError):
      let messageStart: String
      if let e = maybeError {
        messageStart = """
        Remote Config fetch failed due to the following issue:

        \(e.localizedDescription)
        """
      } else {
        messageStart = """
        Remote Config fetch failed due to an error in Remote Config execution.
        """
      }
      return """
      \(messageStart)

      Please verify that your Remote Config setup is working as expected. In a production build, the Promoted SDK will start up and run normally, but Remote Config will not be available.
      """
    case .serviceConfigError(let s):
      return """
      Remote Config failed to initialize due to the following issue:

      \(s)

      Please check your build setup. In a production build, the Promoted SDK will start up and run normally, but Remote Config will not be available.
      """
    }
  }
}
#endif

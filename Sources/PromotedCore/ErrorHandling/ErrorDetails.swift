#if DEBUG
import Foundation

public protocol ErrorDetails {
  var details: String { get }
}

// MARK: - String Constants
fileprivate extension ErrorDetails {

  static let internalErrorDetails = """
  An internal error occurred in the Promoted SDK. Please email bugs@promoted.ai and provide the error code.
  """

  static let deliveryMayBeImpaired = """
  If this issue is released to production, it WILL impair Promoted Delivery and possibly affect revenue at $partner. Please verify any local changes carefully before merging.
  """

  static let deliveryWillBeDisabled = """
  If this issue is released to production, it WILL DISABLE Promoted Delivery and possibly affect revenue at $partner. Please verify any local changes carefully before merging.
  """

  static let checkRemoteConfigSetup = """
  Please check your Remote Config setup. In a production build, the Promoted SDK will start up and run normally, but Remote Config will not be available.
  """

  static let checkRemoteConfigEnumValues = """
  If you are using Remote Config, check that you specified a valid enumeration value.
  """
}

// MARK: - ClientConfigError
extension ClientConfigError: ErrorDetails {
  public var details: String {
    switch self {
    case .invalidURL(let url):
      return """
      An invalid URL was supplied for `ClientConfig.metricsLoggingURL`:

      \(url)

      \(Self.deliveryWillBeDisabled)
      """
    case .missingAPIKey:
      return """
      No API key was provided via `ClientConfig.metricsLoggingAPIKey`.

      \(Self.deliveryWillBeDisabled)
      """
    case .missingDevAPIKey:
      return """
      You specified `ClientConfig.devMetricsLoggingURL` but not `ClientConfig.devMetricsLoggingAPIKey`.
      """
    case .invalidMetricsLoggingWireFormat:
      return """
      Invalid value for enum `ClientConfig.metricsLoggingWireFormat`. Defaulting to `.binary`. \(checkRemoteConfigEnumValues)
      """
    case .invalidXrayLevel:
      return """
      Invalid value for enum `ClientConfig.xrayLevel`. Xray will be disabled. \(checkRemoteConfigEnumValues)
      """
    case .invalidOSLogLevel:
      return """
      Invalid value for enum `ClientConfig.osLogLevel`. Console logging will be disabled. \(checkRemoteConfigEnumValues)
      """
    case .invalidDiagnosticsSamplingEndDateString(let s):
      return """
      You indicated an end date for diagnostic sampling that does not appear to be in the format yyyy-MM-dd:

      \(s)

      Diagnostics sampling will be disabled.
      """
    case .invalidMetricsLoggingErrorHandling:
      // This will only appear in debug builds, where the default is `.modalDialog`.
      return """
      Invalid value for enum `ClientConfig.metricsLoggingErrorHandling`. Error handling will be set to `.modalDialog`. \(checkRemoteConfigEnumValues)
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
      Network connection not specified. You are using `ModuleConfig.coreConfig()`, which requires a custom network connection. Did you mean to use `ModuleConfig.defaultConfig()`?

      \(Self.deliveryWillBeDisabled)
      """
    }
  }
}

// MARK: - MetricsLoggerError
extension MetricsLoggerError: ErrorDetails {
  public var details: String {
    switch self {
    case .missingLogUserIDInUserMessage, .missingLogUserIDInLogRequest:
      return """
      An event was logged with no log user ID. This may be due to a recent change in Promoted initialization. Examples include changes to your AppDelegate class, or calls to the Promoted SDK method startSessionAndLogUser().

      \(Self.deliveryMayBeImpaired)
      """
    case .missingJoinableFieldsInImpression:
      return """
      An impression was logged with no content ID or insertion ID. This may be due to a recent change to a list/collection view, or the data model that powers this view.

      \(Self.deliveryMayBeImpaired)
      """
    case .missingJoinableFieldsInAction:
      return """
      An action was logged with no impression ID, content ID, or insertion ID. This may be due to a recent change to a list/collection view, or the data model that powers this view.

      \(Self.deliveryMayBeImpaired)
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

      \(Self.checkRemoteConfigSetup)
      """
    case .emptyConfig:
      return """
      Remote Config returned an empty configuration. \(Self.checkRemoteConfigSetup)
      """
    case .localCacheEncodeError(let error):
      return """
      An error occured when writing Remote Config to local cache:

      \(error.localizedDescription)

      \(Self.checkRemoteConfigSetup)
      """
    }
  }
}

// MARK: - RemoteConfigConnectionError
extension RemoteConfigConnectionError: ErrorDetails {
  public var details: String {
    switch self {
    case .failed(let maybeError):
      if let e = maybeError {
        return """
        Remote Config fetch failed due to the following issue:

        \(e.localizedDescription)

        \(Self.checkRemoteConfigSetup)
        """
      } else {
        return """
        Remote Config fetch failed due to an error in Remote Config execution.

        \(Self.checkRemoteConfigSetup)
        """
      }
    case .serviceConfigError(let errorMessage):
      return """
      Remote Config failed to initialize due to the following issue:

      \(errorMessage)

      \(Self.checkRemoteConfigSetup)
      """
    }
  }
}
#endif

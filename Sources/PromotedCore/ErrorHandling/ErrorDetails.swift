#if DEBUG || PROMOTED_ERROR_HANDLING
import Foundation

/** Provides details for the ErrorHandlerVC. Public for ReactNativeMetrics. */
public protocol ErrorDetails {
  var details: String { get }
}

// MARK: - String Constants
public extension ErrorDetails {
  static var internalErrorDetails: String { """
  An internal error occurred in the Promoted SDK. Please email bugs@promoted.ai and provide the error code.
  """ }

  static var deliveryMayBeImpaired: String { """
  If this issue is released to production, it WILL impair Promoted Delivery and possibly affect revenue at $partner. Please verify any local changes carefully before merging.
  """ }

  static var deliveryWillBeDisabled: String { """
  If this issue is released to production, it WILL DISABLE Promoted Delivery and possibly affect revenue at $partner. Please verify any local changes carefully before merging.
  """ }

  static var checkRemoteConfigSetup: String { """
  Please check your Remote Config setup. In a production build, the Promoted SDK will start up and run normally, but Remote Config will not be available.
  """ }

  static var checkRemoteConfigEnumValues: String { """
  If you are using Remote Config, check that you specified a valid enumeration value.
  """ }
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
    case .headersContainReservedField(let field):
      return """
      When connecting to a Promoted metrics backend, do not specify an HTTP header with field:

      \(field)

      \(Self.deliveryWillBeDisabled)
      """
    case .invalidMetricsLoggingWireFormat:
      return """
      Invalid value for enum `ClientConfig.metricsLoggingWireFormat`. Defaulting to `.binary`. \(Self.checkRemoteConfigEnumValues)
      """
    case .invalidXrayLevel:
      return """
      Invalid value for enum `ClientConfig.xrayLevel`. Xray will be disabled. \(Self.checkRemoteConfigEnumValues)
      """
    case .invalidOSLogLevel:
      return """
      Invalid value for enum `ClientConfig.osLogLevel`. Console logging will be disabled. \(Self.checkRemoteConfigEnumValues)
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
      Invalid value for enum `ClientConfig.metricsLoggingErrorHandling`. Error handling will be set to `.modalDialog`. \(Self.checkRemoteConfigEnumValues)
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

// MARK: JSONEncodingError
extension JSONEncodingError: ErrorDetails {
  public var details: String {
    switch self {
    case .utf8ConversionError(let message):
      return """
      Conversion to/from UTF-8 failed for message:

      \(message.debugDescription)

      \(Self.deliveryMayBeImpaired)
      """
    }
  }
}

// MARK: - MetricsLoggerError
extension MetricsLoggerError: ErrorDetails {
  public var details: String {
    switch self {
    case .missingAnonUserIDInUserMessage, .missingAnonUserIDInLogRequest:
      return """
      An event was logged with no log user ID. This may be due to a recent change in Promoted initialization. Examples include changes to your AppDelegate class, or calls to the Promoted SDK method startSessionAndLogUser().

      \(Self.deliveryMayBeImpaired)
      """
    case .missingJoinableIDsInImpression:
      return """
      An impression was logged with no content ID or insertion ID. This may be due to a recent change to a list/collection view, or the data model that powers this view.

      \(Self.deliveryMayBeImpaired)
      """
    case .missingJoinableIDsInAction:
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
      Remote Config returned an empty configuration. The remote config will be ignored. \(Self.checkRemoteConfigSetup)
      """
    case .invalidConfig(let error):
      return """
      Remote Config returned an invalid configuration. The remote config will be ignored.

      \(error.localizedDescription)

      \(Self.checkRemoteConfigSetup)
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

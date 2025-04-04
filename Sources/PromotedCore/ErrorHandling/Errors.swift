import Foundation
import SwiftProtobuf

// MARK: - NSErrorProperties
public protocol NSErrorProperties {
  
  var domain: String { get }
  
  var code: Int { get }

  var externalDescription: String { get }
}

public extension NSErrorProperties {

  var domain: String { "ai.promoted" }
}

// MARK: - Error
public extension Error {

  var externalDescription: String {
    let description = String(describing: self)
    return description.prefix(1).capitalized + description.dropFirst()
  }

  func asErrorProperties() -> NSErrorProperties? {
    switch self {
    case let e as NSErrorProperties:
      return e
    case let e as NSError:
      return NSErrorPropertiesWrapper(error: e)
    default:
      return nil
    }
  }
}

class NSErrorPropertiesWrapper: NSErrorProperties {

  public let domain: String

  public let code: Int

  public let externalDescription: String

  init(error: NSError) {
    self.domain = error.domain
    self.code = error.code
    self.externalDescription = error.debugDescription
  }
}

// MARK: - ClientConfigError
/** Errors produced by `ClientConfig` on invalid settings. */
public enum ClientConfigError: Error {

  /// Invalid URL string was provided prior to network send.
  case invalidURL(urlString: String)

  /// `ClientConfig` is missing the API key.
  case missingAPIKey

  /// Request headers contain a field that has been reserved for
  /// use in Promoted servers.
  case headersContainReservedField(field: String)

  /// Specified wire format doesn't exist.
  case invalidMetricsLoggingWireFormat

  case invalidXrayLevel

  case invalidOSLogLevel

  /// `ClientConfig.diagnosticsSamplingPercentage` was specified,
  /// but a valid date was not given for
  /// `diagnosticsSamplingEndDateString`.
  case invalidDiagnosticsSamplingEndDateString(_ s: String)

  case invalidMetricsLoggingErrorHandling
}

extension ClientConfigError: NSErrorProperties {

  public var code: Int {
    switch self {
    case .invalidURL(_):
      return 1001
    case .missingAPIKey:
      return 1002
    case .headersContainReservedField(_):
      return 1003
    case .invalidMetricsLoggingWireFormat:
      return 1004
    case .invalidXrayLevel:
      return 1005
    case .invalidOSLogLevel:
      return 1006
    case .invalidDiagnosticsSamplingEndDateString(_):
      return 1007
    case .invalidMetricsLoggingErrorHandling:
      return 1008
    }
  }
}

// MARK: - ModuleConfigError
/** Errors produced by `Module` on invalid `ModuleConfig`. */
public enum ModuleConfigError: Error {
  /// No `NetworkConnection` was provided.
  case missingNetworkConnection
}

extension ModuleConfigError: NSErrorProperties {

  public var code: Int {
    switch self {
    case .missingNetworkConnection:
      return 2001
    }
  }
}

// MARK: - BinaryEncodingError
extension BinaryEncodingError: NSErrorProperties {
  public var domain: String { "com.google.protobuf" }

  public var code: Int {
    switch self {
    case .missingRequiredFields:
      return 3001
    case .anyTranscodeFailure:
      return 3002
    }
  }
}

// MARK: JSONEncodingError
public enum JSONEncodingError: Error {
  case utf8ConversionError(message: Message)
}

extension JSONEncodingError: NSErrorProperties {

  public var code: Int {
    switch self {
    case .utf8ConversionError(_):
      return 7001
    }
  }
}

// MARK: - MetricsLoggerError
/** Errors produced by `MetricsLogger`. */
public enum MetricsLoggerError: Error {
  /// Properties message serialization failed. Non-fatal.
  case propertiesSerializationError(underlying: Error)

  /// Logging invoked from non-main thread.
  case calledFromWrongThread

  /// An unexpected event type was logged. Non-fatal.
  case unexpectedEvent(_ event: Message)

  /// Tried to log a User message without logUserID. Non-fatal.
  case missingLogUserIDInUserMessage

  /// Tried to log a LogRequest batch without logUserID. Non-fatal.
  case missingLogUserIDInLogRequest

  /// Impression without any joinable fields (content ID, insertion ID).
  /// Non-fatal.
  case missingJoinableIDsInImpression

  /// Action without any joinable fields (impression ID, content ID,
  /// insertion ID). Non-fatal.
  case missingJoinableIDsInAction
}

extension MetricsLoggerError: NSErrorProperties {

  public var code: Int {
    switch self {
    case .propertiesSerializationError(_):
      return 4001
    case .calledFromWrongThread:
      return 4002
    case .unexpectedEvent(_):
      return 4003
    case .missingLogUserIDInUserMessage:
      return 4004
    case .missingLogUserIDInLogRequest:
      return 4005
    case .missingJoinableIDsInImpression:
      return 4006
    case .missingJoinableIDsInAction:
      return 4007
    }
  }
}

// MARK: - ClientConfigFetchError
/** Errors produced by `ClientConfigService` when fetching Remote Config. */
public enum ClientConfigFetchError: Error {

  /// Network error when fetching remote config.
  case networkError(_ error: Error)

  /// Remote fetch finished, but provided no config.
  case emptyConfig

  /// Remote fetch finished, but resulting config was invalid.
  /// The remote config will be ignored.
  case invalidConfig(_ error: Error)

  /// Error when persisting fetched config to local cache.
  /// This means that the config will not be applied.
  case localCacheEncodeError(_ error: Error)

  /// Unanticipated error.
  case unknownError(_ error: Error)
}

extension ClientConfigFetchError: NSErrorProperties {

  public var code: Int {
    switch self {
    case .networkError(_):
      return 5001
    case .emptyConfig:
      return 5002
    case .invalidConfig(_):
      return 5003
    case .localCacheEncodeError(_):
      return 5004
    case .unknownError(_):
      return 5005
    }
  }
}

// MARK: - RemoteConfigConnectionError
/** Errors produced by `RemoteConfigConnection`. */
public enum RemoteConfigConnectionError: Error {
  case failed(underlying: Error?)
  case serviceConfigError(_ message: String)
}

extension RemoteConfigConnectionError: NSErrorProperties {
  public var code: Int {
    switch self {
    case .failed(_):
      return 6001
    case .serviceConfigError(_):
      return 6002
    }
  }
}

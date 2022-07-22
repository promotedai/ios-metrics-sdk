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

  /// `ClientConfig` specified a `devMetricsLoggingURL` but did not
  /// provide `devMetricsLoggingAPIKey`.
  case missingDevAPIKey

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
      return 101
    case .missingAPIKey:
      return 102
    case .missingDevAPIKey:
      return 103
    case .invalidMetricsLoggingWireFormat:
      return 104
    case .invalidXrayLevel:
      return 105
    case .invalidOSLogLevel:
      return 106
    case .invalidDiagnosticsSamplingEndDateString(_):
      return 107
    case .invalidMetricsLoggingErrorHandling:
      return 108
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
      return 201
    }
  }
}

// MARK: - BinaryEncodingError
extension BinaryEncodingError: NSErrorProperties {
  public var domain: String { "com.google.protobuf" }

  public var code: Int {
    switch self {
    case .missingRequiredFields:
      return 301
    case .anyTranscodeFailure:
      return 302
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

  /// Tried to log a User message without userID and logUserID. Non-fatal.
  case missingLogUserIDInUserMessage

  /// Tried to log a LogRequest batch without userID and logUserID. Non-fatal.
  case missingLogUserIDInLogRequest

  /// Impression without any joinable fields (content ID, insertion ID).
  /// Non-fatal.
  case missingJoinableFieldsInImpression

  /// Action without any joinable fields (impression ID, content ID,
  /// insertion ID). Non-fatal.
  case missingJoinableFieldsInAction
}

extension MetricsLoggerError: NSErrorProperties {

  public var code: Int {
    switch self {
    case .propertiesSerializationError(_):
      return 401
    case .calledFromWrongThread:
      return 402
    case .unexpectedEvent(_):
      return 403
    case .missingLogUserIDInUserMessage:
      return 404
    case .missingLogUserIDInLogRequest:
      return 405
    case .missingJoinableFieldsInImpression:
      return 406
    case .missingJoinableFieldsInAction:
      return 407
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

  /// Error when persisting fetched config to local cache.
  /// This means that the config will not be applied.
  case localCacheEncodeError(_ error: Error)
}

extension ClientConfigFetchError: NSErrorProperties {

  public var code: Int {
    switch self {
    case .networkError(_):
      return 501
    case .emptyConfig:
      return 502
    case .localCacheEncodeError(_):
      return 503
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
      return 601
    case .serviceConfigError(_):
      return 602
    }
  }
}
import Foundation
import SwiftProtobuf

// MARK: - ErrorHandler

/** Notified when internal errors occur in Promoted logging. */
@objc(PROErrorListener)
public protocol ErrorListener {
  /// Called once per error after call to Promoted logging finishes.
  /// Internal errors are surfaced to clients as `NSError` (see
  /// `ClientConfigError`).
  @objc func promotedLoggerDidError(_ error: NSError)
}

// MARK: - NSErrorProperties
public protocol NSErrorProperties {
  
  var domain: String { get }
  
  var code: Int { get }

  var externalDescription: String { get }
}

extension NSErrorProperties {

  var promotedAIDomain: String { "ai.promoted" }
}

// MARK: - Error
public extension Error {

  var externalDescription: String {
    let description = String(describing: self)
    return description.prefix(1).capitalized + description.dropFirst()
  }

  func asErrorProperties() -> NSErrorProperties {
    switch self {
    case let e as NSErrorProperties:
      return e
    case let e as NSError:
      return NSErrorPropertiesWrapper(error: e)
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
}

extension ClientConfigError: NSErrorProperties {
  public var domain: String { promotedAIDomain }

  public var code: Int {
    switch self {
    case .invalidURL(_):
      return 101
    case .missingAPIKey:
      return 102
    case .missingDevAPIKey:
      return 103
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
  public var domain: String { promotedAIDomain }

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
}

extension MetricsLoggerError: NSErrorProperties {
  public var domain: String { promotedAIDomain }
  
  public var code: Int {
    switch self {
    case .propertiesSerializationError(_):
      return 401
    case .calledFromWrongThread:
      return 402
    case .unexpectedEvent(_):
      return 403
    }
  }
}

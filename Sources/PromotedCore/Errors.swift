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
public protocol NSErrorProperties: CustomDebugStringConvertible {
  
  var domain: String { get }
  
  var code: Int { get }
}

public extension NSErrorProperties {

  var debugDescription: String {
    let description = String(describing: self)
    return description.prefix(1).capitalized + description.dropFirst()
  }
}

extension NSErrorProperties {

  var promotedAIDomain: String { "ai.promoted" }

  func asNSError() -> NSError {
    return NSError(domain: self.domain, code: self.code,
                   userInfo: [NSDebugDescriptionErrorKey: debugDescription])
  }
}

// MARK: - Error
public extension Error {
  func asExternalError() -> Error {
    if let e = self as? NSErrorProperties {
      return e.asNSError()
    }
    return self
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

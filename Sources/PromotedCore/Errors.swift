import Foundation
import SwiftProtobuf

// MARK: - ErrorHandler

/** Notified when internal errors occur in Promoted logging. */
@objc(PROErrorListener)
public protocol ErrorListener {
  /// Called once per error after call to Promoted logging finishes.
  /// Internal errors are surfaced to clients as `NSError` (see
  /// `ClientConfigError`).
  @objc func metricsLoggerDidError(_ error: NSError)
}

// MARK: - NSErrorProperties
protocol NSErrorProperties {
  
  var domain: String { get }
  
  var code: Int { get }
}

extension NSErrorProperties {

  var promotedAIDomain: String { "ai.promoted" }

  var debugDescription: String {
    let description = String(describing: self)
    return description.prefix(1).capitalized + description.dropFirst()
  }

  func asNSError() -> NSError {
    return NSError(domain: self.domain, code: self.code,
                   userInfo: [NSDebugDescriptionErrorKey: debugDescription])
  }
}

// MARK: - Error
extension Error {
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
  var domain: String { promotedAIDomain }

  var code: Int {
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
  var domain: String { promotedAIDomain }

  var code: Int {
    switch self {
    case .missingNetworkConnection:
      return 201
    }
  }
}

// MARK: - BinaryEncodingError
extension BinaryEncodingError: NSErrorProperties {
  var domain: String { "com.google.protobuf" }

  var code: Int {
    switch self {
    case .missingRequiredFields:
      return 301
    case .anyTranscodeFailure:
      return 302
    }
  }
}

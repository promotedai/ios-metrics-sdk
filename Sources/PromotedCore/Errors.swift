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
  
  var message: String? { get }
}

extension NSErrorProperties {

  var promotedAIDomain: String { "ai.promoted" }

  func asNSError() -> NSError {
    var userInfo: [String: Any]? = nil
    if let message = self.message {
      userInfo = ["message": message]
    }
    return NSError(domain: self.domain, code: self.code, userInfo: userInfo)
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

  var message: String? {
    switch self {
    case .invalidURL(let urlString):
      return urlString
    case .missingAPIKey, .missingDevAPIKey:
      return nil
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

  var message: String? { nil }
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

  var message: String? { nil }
}

func NSErrorForUnspecifiedError(_ error: Error) -> NSError {
  return NSError(domain: "ai.promoted", code: 500,
                 userInfo: ["message": error.localizedDescription])
}

import Foundation
import SwiftProtobuf

// MARK: -
/** Network connection used to send log messages to server. */
public protocol NetworkConnection: AnyObject {

  /// Callback for `sendMessage`. Will be invoked on main thread.
  typealias Callback = (Data?, Error?) -> Void

  /// Sends the given message using the given configuration.
  /// Implementations should automatically retry within reason, so that
  /// callers should not need to perform retry on fail.
  ///
  /// - Parameters:
  ///   - message: Payload to deliver. Depending on the
  ///     `metricsLoggingWireFormat` property of `clientConfig`, may
  ///     be serialized as JSON or binary format.
  ///   - clientConfig: Configuration to use to send message.
  ///   - callback: Invoked on completion of the network op.
  ///     `NetworkConnection`s should manage their own retry logic, so
  ///     if `callback` is invoked with an error, that error indicates
  ///     a failure *after* retrying. Clients should not retry further.
  /// - Returns: Data sent over network connection.
  /// - Throws: Propagate any errors thrown by underlying network
  ///    connection or by the methods in `NetworkConnection` extension.
  func sendMessage(_ message: Message,
                   clientConfig: ClientConfig,
                   callback: Callback?) throws -> Data
}

protocol NetworkConnectionSource: NoDeps {
  var networkConnection: NetworkConnection { get }
}

// MARK: -
public extension NetworkConnection {
  /// Returns the URL to use for logging endpoint.
  /// Optional convenience method.
  /// Implementations should propagate `ClientConfigError`s.
  func metricsLoggingURL(clientConfig: ClientConfig) throws -> URL {
    var urlString = clientConfig.metricsLoggingURL
    #if DEBUG
    if !clientConfig.devMetricsLoggingURL.isEmpty {
      urlString = clientConfig.devMetricsLoggingURL
    }
    #endif

    guard let url = URL(string: urlString) else {
      throw ClientConfigError.invalidURL(urlString: urlString)
    }
    return url
  }

  /// Returns binary data to send over the network request.
  /// Optional convenience method.
  /// Implementations should propagate `ClientConfigError`s.
  func bodyData(message: Message, clientConfig: ClientConfig) throws -> Data {
    switch clientConfig.metricsLoggingWireFormat {
    case .binary:
      return try message.serializedData()
    case .json:
      return try message.jsonUTF8Data()
    }
  }

  /// Creates a `URLRequest` for use with the given request. Will set
  /// the API key on the resulting request. Optional convenience method.
  /// Implementations should propagate `ClientConfigError`s.
  func urlRequest(url: URL, data: Data, clientConfig: ClientConfig) throws -> URLRequest {
    var request = URLRequest(url: url)
    var apiKey = clientConfig.metricsLoggingAPIKey
    #if DEBUG
    if !clientConfig.devMetricsLoggingAPIKey.isEmpty {
      apiKey = clientConfig.devMetricsLoggingAPIKey
    }
    #endif

    guard !apiKey.isEmpty else {
      throw ClientConfigError.missingAPIKey
    }
    let field = clientConfig.apiKeyHTTPHeaderField
    request.addValue(apiKey, forHTTPHeaderField: field)
    if clientConfig.metricsLoggingWireFormat == .binary {
      request.addValue("application/protobuf", forHTTPHeaderField: "content-type")
    }
    return request
  }
}

// MARK: - NoOpNetworkConnection
/** Used to avoid runtime error if no `NetworkConnection` is provided. */
final class NoOpNetworkConnection: NetworkConnection {
  func sendMessage(_ message: Message,
                   clientConfig: ClientConfig,
                   callback: Callback?) throws -> Data { Data() }
}

import Foundation
import SwiftProtobuf

// MARK: -
/** Network connection used to send log messages to server. */
public protocol NetworkConnection {
  
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
  ///   - xray: Xray instance to analyze network traffic.
  ///   - callback: Invoked on completion of the network op.
  ///     `NetworkConnection`s should manage their own retry logic, so
  ///     if `callback` is invoked with an error, that error indicates
  ///     a failure *after* retrying. Clients should not retry further.
  /// - Throws: `NetworkConnectionError.messageSerializationError` for
  ///   any errors that occurred in protobuf serialization *prior to*
  ///   the network operation. Errors resulting from the network operation
  ///   are passed through `callback`.
  func sendMessage(_ message: Message,
                   clientConfig: ClientConfig,
                   xray: Xray?,
                   callback: Callback?) throws

  func sendRequest(_ request: URLRequest,
                   data: Data,
                   clientConfig: ClientConfig,
                   callback: Callback?) throws
}

protocol NetworkConnectionSource {
  var networkConnection: NetworkConnection { get }
}

// MARK: -
public extension NetworkConnection {
  func metricsLoggingURL(clientConfig: ClientConfig) throws -> URL {
    #if DEBUG
    let urlString = clientConfig.devMetricsLoggingURL
    #else
    let urlString = clientConfig.metricsLoggingURL
    #endif

    guard let url = URL(string: urlString) else {
      throw NetworkConnectionError.invalidURLError(urlString: urlString)
    }
    return url
  }
  
  func bodyData(message: Message, clientConfig: ClientConfig) throws -> Data {
    switch clientConfig.metricsLoggingWireFormat {
    case .binary:
      return try message.serializedData()
    case .json:
      return try message.jsonUTF8Data()
    }
  }

  func urlRequest(url: URL, data: Data, clientConfig: ClientConfig) -> URLRequest {
    var request = URLRequest(url: url)
    #if DEBUG
    let apiKey = clientConfig.devMetricsLoggingAPIKey
    #else
    let apiKey = clientConfig.metricsLoggingAPIKey
    #endif

    request.addValue(apiKey, forHTTPHeaderField: "x-api-key")
    if clientConfig.metricsLoggingWireFormat == .binary {
      request.addValue("application/protobuf", forHTTPHeaderField: "content-type")
    }
    return request
  }
}

// MARK: - AbstractNetworkConnection
/** DO NOT INSTANTIATE. Base class for NetworkConnection. */
open class AbstractNetworkConnection: NetworkConnection {

  public init() {}

  public func sendMessage(_ message: Message,
                          clientConfig: ClientConfig,
                          xray: Xray?,
                          callback: Callback?) throws {
    do {
      let url = try metricsLoggingURL(clientConfig: clientConfig)
      let data = try bodyData(message: message, clientConfig: clientConfig)
      let request = urlRequest(url: url, data: data, clientConfig: clientConfig)
      xray?.metricsLoggerBatchWillSend(data: data)
      try sendRequest(request, data: data, clientConfig: clientConfig, callback: callback)
    } catch BinaryEncodingError.missingRequiredFields {
      throw NetworkConnectionError.messageSerializationError(message: "Missing required fields.")
    } catch BinaryEncodingError.anyTranscodeFailure {
      throw NetworkConnectionError.messageSerializationError(message: "`Any` transcode failed.")
    } catch {
      throw NetworkConnectionError.unknownError
    }
  }

  open func sendRequest(_ request: URLRequest,
                        data: Data,
                        clientConfig: ClientConfig,
                        callback: Callback?) throws {
    assertionFailure("Don't instantiate AbstractNetworkConnection")
  }
}

// MARK: - NetworkConnectionError
/** Class of errors produced by `NetworkConnection`. */
public enum NetworkConnectionError: Error {
  
  /// Indicates an error in message serialization prior to network send.
  case messageSerializationError(message: String)
  
  /// Indicates an error from the network operation after completion.
  case networkSendError(domain: String, code: Int, errorString: String)
  
  /// Indicates an invalid URL string was provided.
  case invalidURLError(urlString: String)
  
  /// Indicates an error that is not one of the above cases.
  case unknownError
}

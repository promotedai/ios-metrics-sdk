import Foundation
import SwiftProtobuf

#if canImport(GTMSessionFetcherCore)
import GTMSessionFetcherCore
#elseif canImport(GTMSessionFetcher)
import GTMSessionFetcher
#else
#error("Can't import GTMSessionFetcher")
#endif

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
}

// MARK: -
extension NetworkConnection {
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

// MARK: -
/** Uses `GTMSessionFetcher` to perform the network connection. */
class GTMSessionFetcherConnection: NetworkConnection {
  
  private let fetcherService: GTMSessionFetcherService
  
  init() {
    fetcherService = GTMSessionFetcherService()
  }
  
  func sendMessage(_ message: Message,
                   clientConfig: ClientConfig,
                   xray: Xray?,
                   callback: Callback?) throws {
    do {
      let url = try metricsLoggingURL(clientConfig: clientConfig)
      let messageData = try bodyData(message: message, clientConfig: clientConfig)
      let request = urlRequest(url: url, data: messageData, clientConfig: clientConfig)
      let fetcher = fetcherService.fetcher(with: request)
      fetcher.isRetryEnabled = true
      fetcher.bodyData = messageData
      xray?.metricsLoggerBatchWillSend(data: messageData)
      fetcher.beginFetch { (data, error) in
        var callbackError = error
        if let e = error as NSError? {
          var errorString = ""
          if let data = e.userInfo["data"] as? Data {
            errorString = String(decoding: data, as: UTF8.self)
          }
          callbackError = NetworkConnectionError.networkSendError(
              domain: e.domain, code: e.code, errorString: errorString)
        }
        callback?(data, callbackError)
      }
    } catch BinaryEncodingError.missingRequiredFields {
      throw NetworkConnectionError.messageSerializationError(message: "Missing required fields.")
    } catch BinaryEncodingError.anyTranscodeFailure {
      throw NetworkConnectionError.messageSerializationError(message: "`Any` transcode failed.")
    } catch {
      throw NetworkConnectionError.unknownError
    }
  }
}

// MARK: -
/** Class of errors produced by `NetworkConnection`. */
enum NetworkConnectionError: Error {
  
  /// Indicates an error in message serialization prior to network send.
  case messageSerializationError(message: String)
  
  /// Indicates an error from the network operation after completion.
  case networkSendError(domain: String, code: Int, errorString: String)
  
  /// Indicates an invalid URL string was provided.
  case invalidURLError(urlString: String)
  
  /// Indicates an error that is not one of the above cases.
  case unknownError
}

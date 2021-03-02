import Foundation
import SwiftProtobuf

#if canImport(GTMSessionFetcherCore)
import GTMSessionFetcherCore
#elseif canImport(GTMSessionFetcher)
import GTMSessionFetcher
#else
#error("Can't import GTMSessionFetcher")
#endif

public protocol NetworkConnection {
  typealias Callback = (Data?, Error?) -> Void
  func sendMessage(_ message: Message, url: URL, clientConfig: ClientConfig,
                   callback: Callback?) throws
}

public class GTMSessionFetcherConnection: NetworkConnection {
  
  private let fetcherService: GTMSessionFetcherService
  
  public init() {
    fetcherService = GTMSessionFetcherService()
  }
  
  public func sendMessage(_ message: Message, url: URL, clientConfig: ClientConfig,
                          callback: Callback?) throws {
    do {
      let messageData = try bodyData(message: message, clientConfig: clientConfig)
      var request = URLRequest(url: url)
      if let apiKey = clientConfig.metricsLoggingAPIKey {
        request.addValue(apiKey, forHTTPHeaderField: "x-api-key")
      }
      if clientConfig.metricsLoggingWireFormat == .base64EncodedBinary {
        request.addValue("text/plain", forHTTPHeaderField: "content-type")
        request.addValue("Base64", forHTTPHeaderField: "Content-Transfer-Encoding")
      }
      let fetcher = fetcherService.fetcher(with: request)
      fetcher.bodyData = messageData
      fetcher.beginFetch { (data, error) in
        callback?(data, error)
      }
    } catch BinaryEncodingError.missingRequiredFields {
      throw NetworkConnectionError.messageSerializationError(message: "Missing required fields.")
    } catch BinaryEncodingError.anyTranscodeFailure {
      throw NetworkConnectionError.messageSerializationError(message: "Any transcode failed.")
    } catch {
      throw NetworkConnectionError.unknownError
    }
  }
  
  private func bodyData(message: Message, clientConfig: ClientConfig) throws -> Data {
    switch clientConfig.metricsLoggingWireFormat {
    case .base64EncodedBinary:
      return try message.serializedData().base64EncodedData()
    case .binary:
      return try message.serializedData()
    case .json:
      return try message.jsonUTF8Data()
    }
  }
}

enum NetworkConnectionError: Error {
  case messageSerializationError(message: String)
  case unknownError
}

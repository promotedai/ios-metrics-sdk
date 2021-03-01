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
  func sendMessage(_ message: Message, url: URL, callback: Callback?) throws
}

public class GTMSessionFetcherConnection: NetworkConnection {
  
  private let fetcherService: GTMSessionFetcherService
  
  init() {
    fetcherService = GTMSessionFetcherService()
  }
  
  public func sendMessage(_ message: Message, url: URL, callback: Callback?) throws {
    do {
      let messageData = try message.serializedData()
      let request = URLRequest(url: url)
      let fetcher = fetcherService.fetcher(with: request)
      fetcher.allowLocalhostRequest = true
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
}

enum NetworkConnectionError: Error {
  case messageSerializationError(message: String)
  case unknownError
}

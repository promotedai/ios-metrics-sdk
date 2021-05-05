import Foundation
import SwiftProtobuf

#if !COCOAPODS
import PromotedCore
#endif

#if canImport(GTMSessionFetcherCore)
import GTMSessionFetcherCore
#elseif canImport(GTMSessionFetcher)
import GTMSessionFetcher
#endif

/** Uses `GTMSessionFetcher` to perform the network connection. */
final class GTMSessionFetcherConnection: NetworkConnection {
  
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
      let data = try bodyData(message: message, clientConfig: clientConfig)
      let request = urlRequest(url: url, data: data, clientConfig: clientConfig)
      recordBytesToSend(data, xray: xray)
      let fetcher = fetcherService.fetcher(with: request)
      fetcher.isRetryEnabled = true
      fetcher.bodyData = data
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

import Foundation
import PromotedAIMetricsSDK

#if canImport(GTMSessionFetcherCore)
import GTMSessionFetcherCore
#elseif canImport(GTMSessionFetcher)
import GTMSessionFetcher
#else
#error("Can't import GTMSessionFetcher")
#endif

/** Uses `GTMSessionFetcher` to perform the network connection. */
public final class GTMSessionFetcherConnection: NetworkConnection {
  
  private let fetcherService: GTMSessionFetcherService
  
  public init() {
    fetcherService = GTMSessionFetcherService()
  }
  
  public func sendMessage(_ message: Message,
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

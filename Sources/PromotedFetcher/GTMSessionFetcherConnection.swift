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
final class GTMSessionFetcherConnection: AbstractNetworkConnection {
  
  private let fetcherService: GTMSessionFetcherService

  override init() {
    fetcherService = GTMSessionFetcherService()
  }

  override func sendRequest(_ request: URLRequest,
                            data: Data,
                            clientConfig: ClientConfig,
                            callback: Callback?) throws {
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
  }
}

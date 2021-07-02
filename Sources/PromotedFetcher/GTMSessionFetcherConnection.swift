import Foundation
import SwiftProtobuf

#if SWIFT_PACKAGE
import PromotedCore
#endif

#if canImport(GTMSessionFetcherCore)
import GTMSessionFetcherCore
#elseif canImport(GTMSessionFetcher)
import GTMSessionFetcher
#else
#error("Can't import GTMSessionFetcher")
#endif

/** Uses `GTMSessionFetcher` to perform the network connection. */
final class GTMSessionFetcherConnection: NetworkConnection {
  
  private let fetcherService: GTMSessionFetcherService

  init() {
    fetcherService = GTMSessionFetcherService()
  }

  func sendMessage(_ message: Message,
                   clientConfig: ClientConfig,
                   callback: Callback?) throws -> Data {
    let url = try metricsLoggingURL(clientConfig: clientConfig)
    let data = try bodyData(message: message, clientConfig: clientConfig)
    let request = try urlRequest(url: url, data: data, clientConfig: clientConfig)
    let fetcher = fetcherService.fetcher(with: request)
    fetcher.isRetryEnabled = true
    fetcher.bodyData = data
    fetcher.beginFetch { (data, error) in callback?(data, error) }
    return data
  }
}

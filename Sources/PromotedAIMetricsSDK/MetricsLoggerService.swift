import Foundation

#if canImport(GTMSessionFetcherCore)
import GTMSessionFetcherCore
#elseif canImport(GTMSessionFetcher)
import GTMSessionFetcher
#else
#error("Can't import GTMSessionFetcher")
#endif

@objc(PROMetricsLoggerService)
open class MetricsLoggerService: NSObject, ClientConfigProvider {
  
  private var cachedClientConfigService: ClientConfigService?
  private var clientConfigService: ClientConfigService {
    if cachedClientConfigService == nil {
      cachedClientConfigService = ClientConfigService(provider: self)
    }
    return cachedClientConfigService!
  }
  
  @objc public var config: ClientConfig {
    return clientConfigService.config
  }
  
  private var cachedMetricsLogger: MetricsLogger?
  @objc public var metricsLogger: MetricsLogger {
    let _ = clientConfigService  // Force client config to initialize.
    if cachedMetricsLogger == nil {
      cachedMetricsLogger = makeLogger(metricsLoggingURL: metricsLoggingURL,
                                       fetcherService: fetcherService,
                                       clock: clock)
    }
    return cachedMetricsLogger!
  }
  
  private let metricsLoggingURL: URL
  private let fetcherService: GTMSessionFetcherService
  private let clock: Clock
  
  @objc public convenience init(metricsLoggingURL: URL) {
    self.init(metricsLoggingURL: metricsLoggingURL,
              fetcherService: GTMSessionFetcherService(),
              clock: SystemClock())
  }

  public init(metricsLoggingURL: URL,
              fetcherService: GTMSessionFetcherService,
              clock: Clock) {
    self.fetcherService = fetcherService
    self.metricsLoggingURL = metricsLoggingURL
    self.clock = clock
    self.cachedClientConfigService = nil
    self.cachedMetricsLogger = nil
  }

  @objc public func fetchClientConfig() {
    clientConfigService.fetchClientConfig()
  }
  
  @objc public func makeLogger(metricsLoggingURL: URL,
                               fetcherService: GTMSessionFetcherService,
                               clock: Clock) -> MetricsLogger {
    return MetricsLogger(metricsLoggingURL: metricsLoggingURL,
                         fetcherService: fetcherService,
                         clock: clock)
  }
  
  @objc public func defaultConfig() -> ClientConfig {
    return ClientConfig()
  }
}

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
      cachedMetricsLogger = makeLogger(clientConfig: config,
                                       fetcherService: fetcherService,
                                       clock: clock)
    }
    return cachedMetricsLogger!
  }
  
  private let fetcherService: GTMSessionFetcherService
  private let clock: Clock
  
  @objc public override convenience init() {
    self.init(fetcherService: GTMSessionFetcherService(),
              clock: SystemClock())
  }

  public init(fetcherService: GTMSessionFetcherService,
              clock: Clock) {
    self.fetcherService = fetcherService
    self.clock = clock
    self.cachedClientConfigService = nil
    self.cachedMetricsLogger = nil
  }

  @objc public func fetchClientConfig() {
    clientConfigService.fetchClientConfig()
  }
  
  @objc open func makeLogger(clientConfig: ClientConfig,
                             fetcherService: GTMSessionFetcherService,
                             clock: Clock) -> MetricsLogger {
    return MetricsLogger(clientConfig: clientConfig,
                         fetcherService: fetcherService,
                         clock: clock)
  }
  
  @objc open func defaultConfig() -> ClientConfig {
    return ClientConfig()
  }
}

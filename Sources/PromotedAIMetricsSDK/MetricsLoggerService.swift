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
  
  private var clientConfigService: ClientConfigService {
    if cachedClientConfigService == nil {
      cachedClientConfigService = ClientConfigService(provider: self, store: store)
    }
    return cachedClientConfigService!
  }
  private var cachedClientConfigService: ClientConfigService?

  @objc public var config: ClientConfig {
    return clientConfigService.config
  }
  
  @objc public var metricsLogger: MetricsLogger {
    if cachedMetricsLogger == nil {
      let _ = clientConfigService  // Force client config to initialize.
      cachedMetricsLogger = makeLogger(clientConfig: config,
                                       fetcherService: fetcherService,
                                       clock: clock,
                                       store: store)
    }
    return cachedMetricsLogger!
  }
  private var cachedMetricsLogger: MetricsLogger?

  private let fetcherService: GTMSessionFetcherService
  private let clock: Clock
  private let store: PersistentStore
    
  @objc public init(fetcherService: GTMSessionFetcherService,
                    clock: Clock,
                    store: PersistentStore) {
    self.fetcherService = fetcherService
    self.clock = clock
    self.store = store
    self.cachedClientConfigService = nil
    self.cachedMetricsLogger = nil
  }

  @objc public func startLoggingSession() {
    clientConfigService.fetchClientConfig()
  }
  
  @objc open func makeLogger(clientConfig: ClientConfig,
                             fetcherService: GTMSessionFetcherService,
                             clock: Clock,
                             store: PersistentStore) -> MetricsLogger {
    return MetricsLogger(clientConfig: clientConfig,
                         fetcherService: fetcherService,
                         clock: clock,
                         store: store)
  }
  
  @objc open func defaultConfig() -> ClientConfig {
    return ClientConfig()
  }
}

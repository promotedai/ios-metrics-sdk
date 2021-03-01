import Foundation

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
                                       connection: connection,
                                       clock: clock,
                                       store: store)
    }
    return cachedMetricsLogger!
  }
  private var cachedMetricsLogger: MetricsLogger?

  private let connection: NetworkConnection
  private let clock: Clock
  private let store: PersistentStore

  public init(connection: NetworkConnection = GTMSessionFetcherConnection(),
              clock: Clock = SystemClock(),
              store: PersistentStore = UserDefaultsPersistentStore()) {
    self.connection = connection
    self.clock = clock
    self.store = store
    self.cachedClientConfigService = nil
    self.cachedMetricsLogger = nil
  }

  @objc public func startLoggingSession() {
    clientConfigService.fetchClientConfig()
  }
  
  open func makeLogger(clientConfig: ClientConfig,
                       connection: NetworkConnection,
                       clock: Clock,
                       store: PersistentStore) -> MetricsLogger {
    return MetricsLogger(clientConfig: clientConfig,
                         connection: connection,
                         clock: clock,
                         store: store)
  }
  
  @objc open func defaultConfig() -> ClientConfig {
    return ClientConfig()
  }
}

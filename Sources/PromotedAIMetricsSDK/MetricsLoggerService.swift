import Foundation

open class BaseMetricsLoggerService<L>:
    NSObject, ClientConfigDefaultProvider where L: MetricsLogger {

  public private(set) lazy var metricsLogger: L = {
    // Reading the config property initializes clientConfigService.
    return makeLogger(clientConfig: config, connection: connection,
                      clock: clock, store: store)
  } ()

  private lazy var clientConfigService: ClientConfigService = {
    return ClientConfigService(provider: self, store: store)
  } ()

  public var config: ClientConfig {
    return clientConfigService.config
  }

  private let connection: NetworkConnection
  private let clock: Clock
  private let store: PersistentStore

  public init(connection: NetworkConnection = GTMSessionFetcherConnection(),
              clock: Clock = SystemClock.instance,
              store: PersistentStore = UserDefaultsPersistentStore()) {
    self.connection = connection
    self.clock = clock
    self.store = store
  }

  public func startLoggingServices() {
    clientConfigService.fetchClientConfig()
  }

  open func makeLogger(clientConfig: ClientConfig,
                       connection: NetworkConnection,
                       clock: Clock,
                       store: PersistentStore) -> L {
    return MetricsLogger(clientConfig: clientConfig,
                         connection: connection,
                         clock: clock,
                         store: store) as! L
  }
  
  open func defaultConfig() -> ClientConfig {
    return ClientConfig()
  }
}

public class MetricsLoggerService: BaseMetricsLoggerService<MetricsLogger> {}

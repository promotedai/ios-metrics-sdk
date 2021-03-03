import Foundation

open class BaseMetricsLoggerService<L>:
    NSObject, ClientConfigDefaultProvider where L: MetricsLogger {

  public private(set) lazy var metricsLogger: L = {
    // Reading the config property initializes clientConfigService.
    return makeLogger(clientConfig: config, clock: clock, connection: connection,
                      idMap: idMap, store: store)
  } ()

  private lazy var clientConfigService: ClientConfigService = {
    return ClientConfigService(provider: self, store: store)
  } ()

  public var config: ClientConfig {
    return clientConfigService.config
  }

  private let clock: Clock
  private let connection: NetworkConnection
  private let idMap: IDMap
  private let store: PersistentStore

  public init(clock: Clock = SystemClock.instance,
              connection: NetworkConnection = GTMSessionFetcherConnection(),
              idMap: IDMap = SHA1IDMap.instance,
              store: PersistentStore = UserDefaultsPersistentStore()) {
    self.clock = clock
    self.connection = connection
    self.idMap = idMap
    self.store = store
  }

  public func startLoggingServices() {
    clientConfigService.fetchClientConfig()
  }

  open func makeLogger(clientConfig: ClientConfig,
                       clock: Clock,
                       connection: NetworkConnection,
                       idMap: IDMap,
                       store: PersistentStore) -> L {
    return MetricsLogger(clientConfig: clientConfig,
                         clock: clock,
                         connection: connection,
                         idMap: idMap,
                         store: store) as! L
  }
  
  open func defaultConfig() -> ClientConfig {
    return ClientConfig()
  }
}

public class MetricsLoggerService: BaseMetricsLoggerService<MetricsLogger> {}

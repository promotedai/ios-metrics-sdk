import Foundation

/**
 Configures a logging session and its associated `MetricsLogger`.
 
 Typically, instances of `MetricsLogger`s are tied to a
 `MetricsLoggingService`, which configures the logging environment and
 maintains a `MetricLogger` for the lifetime of the service. You may
 choose to make `MetricsLoggerService` a singleton, which makes its
 corresponding `MetricLogger` a singleton. You may also choose to
 instantiate `MetricsLoggingService` and hold a reference to the instance.
 
 The service also provides a facility to create `ImpressionLogger`s.
 
 You can create multiple instances of the service with different backends
 if desired. However, you should not create multiple services that point
 at the same backend.
 
 Use from main thread only.
 
 # Usage
 Create and configure the service when your app starts, then retrieve the
 `MetricsLogger` instance from the service after it has been configured.
 Alternatively, create `ImpressionLogger` instances using the service.
 
 ## Example:
 ~~~
 let service = MetricsLoggingService(...)
 service.startLoggingServices()
 let logger = service.metricsLogger
 let impressionLogger = service.impressionLogger(dataSource: ...)
 ~~~
 */
@objc(PROMetricsLoggerService)
public class MetricsLoggerService: NSObject, ClientConfigDefaultProvider {

  public private(set) lazy var metricsLogger: MetricsLogger = {
    // Reading the config property initializes clientConfigService.
    return MetricsLogger(messageProvider: self.messageProvider,
                         clientConfig: self.config,
                         clock: self.clock,
                         connection: self.connection,
                         idMap: self.idMap,
                         store: self.store)
  } ()

  private lazy var clientConfigService: ClientConfigService = {
    return ClientConfigService(provider: self, store: store)
  } ()

  public var config: ClientConfig {
    return clientConfigService.config
  }

  public let clock: Clock
  private let connection: NetworkConnection
  private let idMap: IDMap
  private let messageProvider: MessageProvider
  private let store: PersistentStore

  public init(messageProvider: MessageProvider) {
    self.clock = SystemClock.instance
    self.connection = GTMSessionFetcherConnection()
    self.idMap = SHA1IDMap.instance
    self.messageProvider = messageProvider
    self.store = UserDefaultsPersistentStore()
  }
  
  public init(clock: Clock,
              connection: NetworkConnection,
              idMap: IDMap,
              messageProvider: MessageProvider,
              store: PersistentStore) {
    self.clock = clock
    self.connection = connection
    self.idMap = idMap
    self.messageProvider = messageProvider
    self.store = store
  }

  /// Call this to start logging services, prior to accessing the logger.
  func startLoggingServices() {
    clientConfigService.fetchClientConfig()
  }

  func defaultConfig() -> ClientConfig {
    return ClientConfig()
  }

  @objc public func impressionLogger(
      dataSource: ImpressionLoggerDataSource) -> ImpressionLogger {
    return ImpressionLogger(dataSource: dataSource,
                            metricsLogger: self.metricsLogger,
                            clock: self.clock)
  }
}

import Foundation

/**
 Configures a logging session and its associated `MetricsLogger`.
 
 Typically, instances of `MetricsLogger`s are tied to a
 `MetricsLoggingService`, which configures the logging environment and
 maintains a `MetricLogger` for the lifetime of the service. You may
 choose to make `MetricsLoggerService` a singleton, which makes its
 corresponding `MetricLogger` a singleton. You may also choose to
 instantiate `MetricsLoggingService` and hold a reference to the instance.
 
 You can create multiple instances of the service with different backends
 if desired. However, you should not create multiple services that point
 at the same backend.
 
 # Usage
 Create and configure the service when your app starts, then retrieve the
 `MetricsLogger` instance from the service after it has been configured.
 
 ## Example:
 ~~~
 let service = MetricsLoggingService(...)
 service.startLoggingServices()
 let logger = service.metricsLogger
 ~~~
 
 # Subclassing
 Subclass the service to specialize the type of the `MetricsLogger` it
 creates. If you want to use the resulting subclass in Objective C, you'll
 need to create an Objective C wrapper for the subclass, because Swift
 generics aren't supported in Objective C.
 
 ## Example:
 ~~~
 public class MyLoggerService:
     BaseMetricsLoggerService<MyLogger> {
   public func makeLogger(clientConfig: ClientConfig,
                          clock: Clock,
                          connection: NetworkConnection,
                          idMap: IDMap,
                          store: PersistentStore) -> MyLogger {
     return MyLogger(...)
   }
 }
 
 @objc public class MyLoggerServiceObjCWrapper: NSObject {
   @objc public var metricsLogger: MyLogger {
     return myLoggerService.metricsLogger
   }
 }
 ~~~
 */
open class BaseMetricsLoggerService<L>:
    ClientConfigDefaultProvider where L: MetricsLogger {

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

  /// Call this to start logging services, prior to accessing the logger.
  public func startLoggingServices() {
    clientConfigService.fetchClientConfig()
  }

  /// Subclasses should override to provide an instance of its
  /// `MetricsLogger`. Will only be invoked once by the service,
  /// to create the logger lazily.
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

/** Default implementation of `BaseMetricsLoggerService`. */
public class MetricsLoggerService: BaseMetricsLoggerService<MetricsLogger> {}

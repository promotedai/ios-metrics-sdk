import Foundation

// MARK: -
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
 
 ## Example (using instance):
 ~~~
 let service = MetricsLoggingService(messageProvider: ...)
 service.startLoggingServices()
 let logger = service.metricsLogger
 let impressionLogger = service.impressionLogger(dataSource: ...)
 ~~~
 
 ## Example (using sharedService):
 ~~~
 // Call this first before accessing the instance.
 MetricsLoggerService.startServices(messageProvider: ...)
 let service = MetricsLoggerService.sharedService
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

  var defaultConfig: ClientConfig {
    return initialConfig
  }

  public let clock: Clock
  private let connection: NetworkConnection
  private let initialConfig: ClientConfig
  private let idMap: IDMap
  private let messageProvider: MessageProvider
  private let store: PersistentStore

  public init(messageProvider: MessageProvider,
              initialConfig: ClientConfig) {
    self.clock = SystemClock.instance
    self.connection = GTMSessionFetcherConnection()
    self.idMap = SHA1IDMap.instance
    self.initialConfig = initialConfig
    self.messageProvider = messageProvider
    self.store = UserDefaultsPersistentStore()
  }
  
  public init(clock: Clock,
              connection: NetworkConnection,
              idMap: IDMap,
              initialConfig: ClientConfig,
              messageProvider: MessageProvider,
              store: PersistentStore) {
    self.clock = clock
    self.connection = connection
    self.idMap = idMap
    self.initialConfig = initialConfig
    self.messageProvider = messageProvider
    self.store = store
  }

  /// Call this to start logging services, prior to accessing the logger.
  public func startLoggingServices() {
    clientConfigService.fetchClientConfig()
  }

  @objc public func impressionLogger(dataSource: ImpressionLoggerDataSource)
      -> ImpressionLogger {
    return ImpressionLogger(dataSource: dataSource,
                            metricsLogger: self.metricsLogger,
                            clock: self.clock)
  }
  
  @objc public func impressionLogger(sectionedContent: [[Content]])
      -> ImpressionLogger {
    return ImpressionLogger(sectionedContent: sectionedContent,
                            metricsLogger: self.metricsLogger,
                            clock: self.clock)
  }
  
  @objc public func scrollTracker(sectionedContent: [[Content]]) -> ScrollTracker {
    let impressionLogger = ImpressionLogger(sectionedContent: sectionedContent,
                                            metricsLogger: self.metricsLogger,
                                            clock: self.clock)
    return ScrollTracker(sectionedContent: sectionedContent,
                         impressionLogger: impressionLogger,
                         clock: self.clock)
  }
}

// MARK: - Singleton support for `MetricsLoggingService`
public extension MetricsLoggerService {

  static var messageProvider: MessageProvider?
  static var initialConfig: ClientConfig?
  
  static func startServices(messageProvider: MessageProvider,
                            initialConfig: ClientConfig) {
    self.messageProvider = messageProvider
    self.initialConfig = initialConfig
    self.sharedService.startLoggingServices()
  }

  /// Returns the shared logger. Causes error if `messageProvider` is not set.
  @objc static let sharedService =
      MetricsLoggerService(messageProvider: messageProvider!,
                           initialConfig: initialConfig!)
}

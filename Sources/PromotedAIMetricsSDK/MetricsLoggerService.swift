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
 let service = MetricsLoggingService(initialConfig: ...)
 service.startLoggingServices()
 let logger = service.metricsLogger
 let impressionLogger = service.impressionLogger(dataSource: ...)
 ~~~
 
 ## Example (using sharedService):
 ~~~
 // Call this first before accessing the instance.
 MetricsLoggerService.startServices(initialConfig: ...)
 let service = MetricsLoggerService.sharedService
 let logger = service.metricsLogger
 let impressionLogger = service.impressionLogger(dataSource: ...)
 ~~~
 */
@objc(PROMetricsLoggerService)
public class MetricsLoggerService: NSObject, ClientConfigDefaultProvider {

  @objc public private(set) lazy var metricsLogger: MetricsLogger = {
    // Reading `self.config` initializes clientConfigService.
    return MetricsLogger(clientConfig: self.config,
                         clock: self.clock,
                         connection: self.connection,
                         deviceInfo: self.deviceInfo,
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
  private let deviceInfo: DeviceInfo
  private let initialConfig: ClientConfig
  private let idMap: IDMap
  private let store: PersistentStore

  @objc public init(initialConfig: ClientConfig) {
    self.clock = SystemClock.instance
    self.connection = GTMSessionFetcherConnection()
    self.deviceInfo = CurrentDeviceInfo()
    self.idMap = SHA1IDMap.instance
    self.initialConfig = initialConfig
    self.store = UserDefaultsPersistentStore()
  }
  
  init(clock: Clock,
       connection: NetworkConnection,
       deviceInfo: DeviceInfo,
       idMap: IDMap,
       initialConfig: ClientConfig,
       store: PersistentStore) {
    self.clock = clock
    self.connection = connection
    self.deviceInfo = deviceInfo
    self.idMap = idMap
    self.initialConfig = initialConfig
    self.store = store
  }

  /// Call this to start logging services, prior to accessing the logger.
  /// Initialization is asynchronous, so this can be called from app
  /// startup without performance penalty. For example, in
  /// `application(_:didFinishLaunchingWithOptions:)`.
  @objc public func startLoggingServices() {
    clientConfigService.fetchClientConfig()
  }

  @objc public func impressionLogger() -> ImpressionLogger {
    return ImpressionLogger(metricsLogger: self.metricsLogger,
                            clock: self.clock)
  }
  
  @objc public func impressionLogger(dataSource: IndexPathDataSource) -> ImpressionLogger {
    let impressionLogger = self.impressionLogger()
    impressionLogger.dataSource = dataSource
    return impressionLogger
  }

  @objc public func scrollTracker() -> ScrollTracker {
    return ScrollTracker(metricsLogger: self.metricsLogger, clock: self.clock)
  }

  #if canImport(UIKit)
  @objc public func scrollTracker(scrollView: UIScrollView) -> ScrollTracker {
    let scrollTracker = self.scrollTracker()
    scrollTracker.scrollView = scrollView
    return scrollTracker
  }
  #endif
}

// MARK: - Singleton support for `MetricsLoggingService`
public extension MetricsLoggerService {

  static var initialConfig: ClientConfig?
  
  @objc static func startServices(initialConfig: ClientConfig) {
    self.initialConfig = initialConfig
    self.sharedService.startLoggingServices()
  }

  /// Returns the shared logger. Causes error if `messageProvider` is not set.
  @objc static let sharedService =
      MetricsLoggerService(initialConfig: initialConfig!)
}

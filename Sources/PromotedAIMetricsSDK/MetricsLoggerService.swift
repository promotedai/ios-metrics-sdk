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
 let impressionLogger = service.impressionLogger()
 ~~~
 
 ## Example (using sharedService):
 ~~~
 // Call this first before accessing the instance.
 MetricsLoggerService.startServices(initialConfig: ...)
 let service = MetricsLoggerService.sharedService
 let logger = service.metricsLogger
 let impressionLogger = service.impressionLogger()
 ~~~
 */
@objc(PROMetricsLoggerService)
public class MetricsLoggerService: NSObject {

  public private(set) lazy var metricsLogger: MetricsLogger = {
    return MetricsLogger(clientConfig: self.config,
                         clock: self.clock,
                         connection: self.connection,
                         deviceInfo: self.deviceInfo,
                         idMap: self.idMap,
                         store: self.store)
  } ()

  var config: ClientConfig {
    return clientConfigService.config
  }

  private var clientConfigService: ClientConfigService
  private let clock: Clock
  private let connection: NetworkConnection
  private let deviceInfo: DeviceInfo
  private let idMap: IDMap
  private let store: PersistentStore

  @objc public convenience init(initialConfig: ClientConfig) {
    self.init(clientConfigService: LocalClientConfigService(initialConfig: initialConfig),
              clock: SystemClock.instance,
              connection: GTMSessionFetcherConnection(),
              deviceInfo: CurrentDeviceInfo(),
              idMap: SHA1IDMap.instance,
              store: UserDefaultsPersistentStore())
  }
  
  public convenience init(clientConfigService: ClientConfigService) {
    self.init(clientConfigService: clientConfigService,
              clock: SystemClock.instance,
              connection: GTMSessionFetcherConnection(),
              deviceInfo: CurrentDeviceInfo(),
              idMap: SHA1IDMap.instance,
              store: UserDefaultsPersistentStore())
  }

  public init(clientConfigService: ClientConfigService,
              clock: Clock,
              connection: NetworkConnection,
              deviceInfo: DeviceInfo,
              idMap: IDMap,
              store: PersistentStore) {
    self.clientConfigService = clientConfigService
    self.clock = clock
    self.connection = connection
    self.deviceInfo = deviceInfo
    self.idMap = idMap
    self.store = store
  }

  /// Call this to start logging services, prior to accessing `logger`.
  /// Initialization is asynchronous, so this can be called from app
  /// startup without performance penalty. For example, in
  /// `application(_:didFinishLaunchingWithOptions:)`.
  @objc public func startLoggingServices() {
    clientConfigService.fetchClientConfig()
  }

  @objc public func impressionLogger() -> ImpressionLogger {
    return ImpressionLogger(metricsLogger: self.metricsLogger, clock: self.clock)
  }

  public func scrollTracker() -> ScrollTracker {
    return ScrollTracker(metricsLogger: self.metricsLogger, clock: self.clock)
  }
}

// MARK: - Singleton support for `MetricsLoggingService`
public extension MetricsLoggerService {

  static var clientConfigService: ClientConfigService?
  
  /// Call this to start logging services, prior to accessing `sharedService`.
  ///
  /// - SeeAlso: `startLoggingServices()`
  @objc static func startServices(initialConfig: ClientConfig) {
    self.clientConfigService = LocalClientConfigService(initialConfig: initialConfig)
    self.sharedService.startLoggingServices()
  }
  
  /// Call this to start logging services, prior to accessing `sharedService`.
  ///
  /// - SeeAlso: `startLoggingServices()`
  static func startServices(clientConfigService: ClientConfigService) {
    self.clientConfigService = clientConfigService
    self.sharedService.startLoggingServices()
  }

  /// Returns the shared logger. Causes error if `startServices` was not called.
  @objc static let sharedService: MetricsLoggerService = {
    assert(clientConfigService != nil, "Call startServices() before accessing sharedService")
    return MetricsLoggerService(clientConfigService: clientConfigService!)
  } ()
}

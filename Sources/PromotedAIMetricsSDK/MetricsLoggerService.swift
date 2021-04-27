import Foundation
import UIKit
import os.log

// MARK: -
/**
 Configures a logging session and its associated `MetricsLogger`.
 
 Typically, instances of `MetricsLogger`s are tied to a
 `MetricsLoggingService`, which configures the logging environment and
 maintains a `MetricsLogger` for the lifetime of the service. 
 
 The service also provides a facility to create `ImpressionLogger`s and
 `ScrollTracker`s.
 
 # Usage
 Create and configure the service when your app starts, then retrieve the
 `MetricsLogger` instance from the service after it has been configured.
 Alternatively, create `ImpressionLogger` instances using the service.

 You may choose to make `MetricsLoggerService` a singleton, which makes its
 corresponding `MetricsLogger` a singleton. You may also choose to
 instantiate `MetricsLoggingService` and hold a reference to the instance.
 In either case, choose one way to create and access `MetricsLoggerService`
 and use it consistently in your app.

 You can create multiple instances of the service with different backends
 if desired. However, you should not create multiple services that point
 at the same backend.
 
 Use from main thread only.
 
 ## Example (using instance):
 ~~~
 let service = MetricsLoggerService(initialConfig: ...)
 service.startLoggingServices()
 let logger = service.metricsLogger
 let impressionLogger = service.impressionLogger()
 let scrollTracker = service.scrollTracker(collectionView: ...)
 ~~~
 
 ## Example (using shared service):
 ~~~
 // Call this first before accessing the instance.
 MetricsLoggerService.startServices(initialConfig: ...)
 let service = MetricsLoggerService.shared
 let logger = service.metricsLogger
 let impressionLogger = service.impressionLogger()
 ~~~
 */
@objc(PROMetricsLoggerService)
public final class MetricsLoggerService: NSObject {

  @objc public private(set) lazy var metricsLogger: MetricsLogger? = {
    let config = self.config
    guard config.loggingEnabled else { return nil }
    return MetricsLogger(clientConfig: config,
                         clock: self.clock,
                         connection: self.connection,
                         deviceInfo: self.deviceInfo,
                         idMap: self.idMap,
                         monitor: self.monitor,
                         osLog: self.metricsLoggerOSLog,
                         store: self.store,
                         xray: self.xray)
  } ()

  public var config: ClientConfig { clientConfigService.config }

  private let clientConfigService: ClientConfigService
  private let clock: Clock
  private let connection: NetworkConnection
  private let deviceInfo: DeviceInfo
  private let idMap: IDMap
  private let monitor: OperationMonitor
  private let store: PersistentStore
  
  private let metricsLoggerOSLog: OSLog?
  private let xrayOSLog: OSLog?

  /// Profiling information for this session.
  public let xray: Xray?

  @objc public convenience init(initialConfig: ClientConfig) {
    let service = LocalClientConfigService(initialConfig: initialConfig)
    self.init(clientConfigService: service,
              clock: SystemClock.instance,
              connection: GTMSessionFetcherConnection(),
              deviceInfo: IOSDeviceInfo(),
              idMap: SHA1IDMap.instance,
              store: UserDefaultsPersistentStore())
  }

  public convenience init(clientConfigService: ClientConfigService) {
    self.init(clientConfigService: clientConfigService,
              clock: SystemClock.instance,
              connection: GTMSessionFetcherConnection(),
              deviceInfo: IOSDeviceInfo(),
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
    self.monitor = OperationMonitor()
    self.store = store
    let config = clientConfigService.config
    if config.osLogEnabled {
      self.metricsLoggerOSLog = OSLog(subsystem: "ai.promoted", category: "MetricsLogger")
      self.xrayOSLog = OSLog(subsystem: "ai.promoted", category: "Xray")
    } else {
      self.metricsLoggerOSLog = nil
      self.xrayOSLog = nil
    }
    if config.xrayEnabled {
      self.xray = Xray(clock: clock,
                       config: config,
                       monitor: monitor,
                       osLog: xrayOSLog)
    } else {
      self.xray = nil
    }
  }

  /// Call this to start logging services, prior to accessing `logger`.
  /// Initialization is asynchronous, so this can be called from app
  /// startup without performance penalty. For example, in
  /// `application(_:didFinishLaunchingWithOptions:)`.
  @objc public func startLoggingServices() {
    clientConfigService.fetchClientConfig()
  }

  /// Returns a new `ImpressionLogger`.
  @objc public func impressionLogger() -> ImpressionLogger? {
    guard let metricsLogger = self.metricsLogger else { return nil }
    return ImpressionLogger(metricsLogger: metricsLogger,
                            clock: self.clock,
                            monitor: self.monitor)
  }

  /// Returns a new `ScrollTracker`.
  @objc func scrollTracker() -> ScrollTracker? {
    guard let metricsLogger = self.metricsLogger else { return nil }
    return ScrollTracker(metricsLogger: metricsLogger,
                         clientConfig: self.config,
                         clock: self.clock,
                         monitor: self.monitor)
  }
}

// MARK: - UIKit support
public extension MetricsLoggerService {
  /// Returns a new `ScrollTracker` tied to the given `UIScrollView`.
  /// The scroll view must contain a `UICollectionView` to track, and
  /// clients must provide the `ScrollTracker` with the `UICollectionView`
  /// via `setFramesFrom(collectionView:...)` to initiate tracking.
  @objc func scrollTracker(scrollView: UIScrollView) -> ScrollTracker? {
    guard let metricsLogger = self.metricsLogger else { return nil }
    return ScrollTracker(metricsLogger: metricsLogger,
                         clientConfig: self.config,
                         clock: self.clock,
                         monitor: self.monitor,
                         scrollView: scrollView)
  }

  /// Returns a new `ScrollTracker` tied to the given `UICollectionView`.
  @objc func scrollTracker(collectionView: UICollectionView) -> ScrollTracker? {
    guard let metricsLogger = self.metricsLogger else { return nil }
    return ScrollTracker(metricsLogger: metricsLogger,
                         clientConfig: self.config,
                         clock: self.clock,
                         monitor: self.monitor,
                         collectionView: collectionView)
  }
}

// MARK: - Singleton support for `MetricsLoggingService`
public extension MetricsLoggerService {

  private static var clientConfigService: ClientConfigService?
  
  /// Call this to start logging services, prior to accessing `sharedService`.
  ///
  /// - SeeAlso: `startLoggingServices()`
  @objc static func startServices(initialConfig: ClientConfig) {
    self.clientConfigService = LocalClientConfigService(initialConfig: initialConfig)
    self.shared.startLoggingServices()
  }
  
  /// Call this to start logging services, prior to accessing `sharedService`.
  ///
  /// - SeeAlso: `startLoggingServices()`
  static func startServices(clientConfigService: ClientConfigService) {
    self.clientConfigService = clientConfigService
    self.shared.startLoggingServices()
  }

  /// Returns the shared logger. Causes error if `startServices` was not called.
  @objc(sharedService)
  static let shared: MetricsLoggerService = {
    assert(clientConfigService != nil, "Call startServices() before accessing shared service")
    return MetricsLoggerService(clientConfigService: clientConfigService!)
  } ()
}

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
    guard config.loggingEnabled else { return nil }
    return MetricsLogger(deps: module)
  } ()

  @objc public var config: ClientConfig { module.clientConfig }
  
  @objc public var xray: Xray? { module.xray }

  private let module: Module

  @objc public init(initialConfig: ClientConfig) {
    self.module = Module(initialConfig: initialConfig)
  }

  @objc public init(moduleConfig: ModuleConfig) {
    self.module = Module(moduleConfig: moduleConfig)
  }

  /// Call this to start logging services, prior to accessing `logger`.
  /// Initialization is asynchronous, so this can be called from app
  /// startup without performance penalty. For example, in
  /// `application(_:didFinishLaunchingWithOptions:)`.
  @objc public func startLoggingServices() {
    module.clientConfigService.fetchClientConfig()
  }

  /// Returns a new `ImpressionLogger`.
  @objc public func impressionLogger() -> ImpressionLogger? {
    guard let metricsLogger = self.metricsLogger else { return nil }
    return ImpressionLogger(metricsLogger: metricsLogger, deps: module)
  }

  /// Returns a new `ScrollTracker`.
  @objc func scrollTracker() -> ScrollTracker? {
    guard let metricsLogger = self.metricsLogger else { return nil }
    return ScrollTracker(metricsLogger: metricsLogger, deps: module)
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
                         scrollView: scrollView,
                         deps: module)
  }

  /// Returns a new `ScrollTracker` tied to the given `UICollectionView`.
  @objc func scrollTracker(collectionView: UICollectionView) -> ScrollTracker? {
    guard let metricsLogger = self.metricsLogger else { return nil }
    return ScrollTracker(metricsLogger: metricsLogger,
                         collectionView: collectionView,
                         deps: module)
  }
}

// MARK: - Singleton support for `MetricsLoggingService`
public extension MetricsLoggerService {

  private static var moduleConfig: ModuleConfig?
  
  /// Call this to start logging services, prior to accessing `sharedService`.
  ///
  /// - SeeAlso: `startLoggingServices()`
  @objc static func startServices(initialConfig: ClientConfig) {
    self.moduleConfig = ModuleConfig()
    self.moduleConfig!.initialConfig = initialConfig
    self.shared.startLoggingServices()
  }
  
  /// Call this to start logging services, prior to accessing `sharedService`.
  ///
  /// - SeeAlso: `startLoggingServices()`
  static func startServices(moduleConfig: ModuleConfig) {
    self.moduleConfig = moduleConfig
    self.shared.startLoggingServices()
  }

  /// Returns the shared logger. Causes error if `startServices` was not called.
  @objc(sharedService)
  static let shared: MetricsLoggerService = {
    assert(moduleConfig != nil, "Call startServices() before accessing shared service")
    return MetricsLoggerService(moduleConfig: moduleConfig!)
  } ()
}

import Foundation
import UIKit
import os.log

// MARK: -
/**
 Configures a logging session and its associated `MetricsLogger`.
 
 Typically, instances of `MetricsLogger`s are tied to a
 `MetricsLoggingService`, which configures the logging environment and
 maintains a `MetricsLogger` for the lifetime of the service. 
 
 The service also provides a facility to create `ImpressionTracker`s and
 `ScrollTracker`s.
 
 # Usage
 Create and configure the service when your app starts, then retrieve the
 `MetricsLogger` instance from the service after it has been configured.
 Alternatively, create `ImpressionTracker` instances using the service.

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
 ```swift
 let service = try MetricsLoggerService(initialConfig: ...)
 try service.startLoggingServices()
 let logger = service.metricsLogger
 let impressionTracker = service.impressionTracker()
 let scrollTracker = service.scrollTracker(collectionView: ...)
 ```
 
 ## Example (using shared service):
 ```swift
 // Call this first before accessing the instance.
 try MetricsLoggerService.startServices(initialConfig: ...)
 let service = MetricsLoggerService.shared
 let logger = service.metricsLogger
 let impressionTracker = service.impressionTracker()
 ```
 
 # PromotedCore vs PromotedMetrics
 The above example uses the `PromotedMetrics` dependency. It's assumed
 that most client integrations will bring in `PromotedMetrics`, which
 supplies a default implementation for `NetworkConnection`. If you pull
 in `PromotedCore`, then the various method/parameter names will have
 `core` in the name (`init(coreInitialConfig:)`,
 `startServices(coreInitialConfig:)`).
 
 # Initialization and error handling
 This service becomes a no-op if it encounters initialization errors,
 either from its initializers or from `startLoggingServices()`.
 It's safe to ignore any errors from `startLoggingServices()`.
 
 Initialization errors may not be logged to analytics.
 
 ## Example (Objective C full error handling):
```objc
 NSError *error = nil;
 PROMetricsLoggerService *service =
     [[PROMetricsLoggerService alloc]
         initWithInitialConfig:config error:&error];
 if (error != nil) {
   LogInitializationError(error);
   return nil;
 }
 [service startLoggingServicesAndReturnError:&error];
 if (error != nil) {
   LogInitializationError(error);
   return nil;
 }
 return service;
```
 
 ## Example (Objective C ignoring errors):
 ```objc
 PROMetricsLoggerService *service =
     [[PROMetricsLoggerService alloc]
         initWithInitialConfig:config error:nil];
 [service startLoggingServicesAndReturnError:nil];
 return service;
 ```
 */
@objc(PROMetricsLoggerService)
public final class MetricsLoggerService: NSObject {

  @objc public private(set) lazy var metricsLogger: MetricsLogger? = {
    guard case .success = startupResult, config.loggingEnabled else {
      return nil
    }
    return MetricsLogger(deps: module)
  } ()

  @objc public var config: ClientConfig { module.clientConfig }

  @objc public var xray: Xray? { module.xray }

  private let module: Module

  public enum StartupResult {
    case pending
    case success
    case failure(error: Error)
  }
  public private(set) var startupResult: StartupResult

  /// Creates a new service with a core configuration.
  /// This does not provide a `NetworkConnection`. If you are not
  /// supplying your own `NetworkConnection`, you should use
  /// `init(initialConfig:)` from the `PromotedMetrics` dependency.
  ///
  /// Initialization errors may not be logged to analytics.
  @objc public convenience init(coreInitialConfig: ClientConfig) throws {
    let moduleConfig = ModuleConfig.coreConfig()
    moduleConfig.initialConfig = coreInitialConfig
    try self.init(moduleConfig: moduleConfig)
  }

  /// Creates a new service with given `ModuleConfig`.
  /// Initialization errors may not be logged to analytics.
  @objc public init(moduleConfig: ModuleConfig) throws {
    self.module = Module(moduleConfig: moduleConfig)
    self.startupResult = .pending
    do {
      try module.initialConfig.validateConfig()
      try module.validateModuleConfigDependencies()
    } catch {
      throw error
    }
  }
}

// MARK: - Startup and app lifecycle
public extension MetricsLoggerService {
  /// Call this to start logging services, prior to accessing `logger`.
  /// Initialization is asynchronous, so this can be called from app
  /// startup without performance penalty. For example, in
  /// `application(_:didFinishLaunchingWithOptions:)`.
  ///
  /// If this method fails or throws an error, then the service becomes
  /// a no-op object that returns `nil` for `metricsLogger`,
  /// `impressionTracker()`, and `scrollTracker()`. In Swift, it's safe
  /// to ignore the thrown error, with `try? service.startLoggingServices()`.
  /// In Objective C, it's safe to ignore the failure/error from
  /// `[service startLoggingServicesAndReturnError:]`.
  ///
  /// Initialization errors may not be logged to analytics.
  @objc func startLoggingServices() throws {
    guard case .pending = startupResult else { return }
    do {
      try module.startLoggingServices()
      let nc = NotificationCenter.default
      nc.addObserver(self,
                     selector: #selector(applicationWillResignActive),
                     name: UIApplication.willResignActiveNotification,
                     object: nil)
      startupResult = .success
    } catch {
      startupResult = .failure(error: error)
      throw error
    }
  }

  @objc private func applicationWillResignActive() {
    if config.flushLoggingOnResignActive {
      metricsLogger?.flush()
    }
  }
}

// MARK: - Impression logging
public extension MetricsLoggerService {

  /// Returns a new `ImpressionTracker`.
  @objc func impressionTracker() -> ImpressionTracker? {
    guard let metricsLogger = self.metricsLogger else { return nil }
    return ImpressionTracker(metricsLogger: metricsLogger, deps: module)
  }

  /// Returns a new `ScrollTracker`.
  @objc func scrollTracker() -> ScrollTracker? {
    guard let metricsLogger = self.metricsLogger else { return nil }
    return ScrollTracker(metricsLogger: metricsLogger, deps: module)
  }

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
  /// This does not provide a `NetworkConnection`. If you are not
  /// supplying your own `NetworkConnection`, you should use
  /// `startServices(initialConfig:)` from the `PromotedMetrics` dependency.
  ///
  /// Equivalent to calling `init`, then `startLoggingServices()` on
  /// the shared service.
  @objc static func startServices(coreInitialConfig: ClientConfig) throws {
    let moduleConfig = ModuleConfig.coreConfig()
    moduleConfig.initialConfig = coreInitialConfig
    try startServices(moduleConfig: moduleConfig)
  }

  /// Call this to start logging services, prior to accessing `sharedService`.
  ///
  /// Equivalent to calling `init`, then `startLoggingServices()` on
  /// the shared service.
  @objc static func startServices(moduleConfig: ModuleConfig) throws {
    self.moduleConfig = moduleConfig
    try self.shared.startLoggingServices()
  }

  /// Returns the shared logger. Causes runtime error if `startServices`
  /// was not called.
  @objc(sharedService)
  static let shared: MetricsLoggerService = {
    assert(moduleConfig != nil, "Call startServices() before accessing shared service")
    return try! MetricsLoggerService(moduleConfig: moduleConfig!)
  } ()
}

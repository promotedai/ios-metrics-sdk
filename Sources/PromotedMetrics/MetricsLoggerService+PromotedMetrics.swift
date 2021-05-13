import Foundation

#if !COCOAPODS
import PromotedCore
#endif

public extension MetricsLoggerService {
  /// Call this to start logging services, prior to accessing `shared`.
  /// Creates a default implementation for `NetworkConnection`.
  ///
  /// Equivalent to calling `init`, then `startLoggingServices()` on
  /// the shared service.
  @objc static func startServices(initialConfig: ClientConfig) throws {
    let moduleConfig = ModuleConfig.defaultConfig()
    moduleConfig.initialConfig = initialConfig
    try startServices(moduleConfig: moduleConfig)
  }

  /// Creates a new service with a core configuration.
  /// Creates a default implementation for `NetworkConnection`.
  @objc convenience init(initialConfig: ClientConfig) throws {
    let moduleConfig = ModuleConfig.defaultConfig()
    moduleConfig.initialConfig = initialConfig
    try self.init(moduleConfig: moduleConfig)
  }
}

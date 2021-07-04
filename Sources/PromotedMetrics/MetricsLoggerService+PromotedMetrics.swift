import Foundation

#if !COCOAPODS
import PromotedCore
#endif

public extension MetricsLoggerService {

  @objc static func startServices(initialConfig: _ObjCClientConfig) throws {
    try startServices(coreInitialConfig: ClientConfig(initialConfig))
  }

  /// Call this to start logging services, prior to accessing `shared`.
  /// Creates a default implementation for `NetworkConnection`.
  ///
  /// Equivalent to calling `init`, then `startLoggingServices()` on
  /// the shared service.
  static func startServices(initialConfig: ClientConfig) throws {
    let moduleConfig = ModuleConfig.defaultConfig()
    moduleConfig.initialConfig = initialConfig
    try startServices(moduleConfig: moduleConfig)
  }

  @objc convenience init(initialConfig: _ObjCClientConfig) throws {
    try self.init(initialConfig: ClientConfig(initialConfig))
  }

  /// Creates a new service with a core configuration.
  /// Creates a default implementation for `NetworkConnection`.
  convenience init(initialConfig: ClientConfig) throws {
    let moduleConfig = ModuleConfig.defaultConfig()
    moduleConfig.initialConfig = initialConfig
    try self.init(moduleConfig: moduleConfig)
  }
}

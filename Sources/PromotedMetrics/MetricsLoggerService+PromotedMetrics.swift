import Foundation

#if !COCOAPODS
import PromotedCore
#endif

public extension MetricsLoggerService {
  /// Call this to start logging services, prior to accessing `sharedService`.
  ///
  /// - SeeAlso: `startLoggingServices()`
  @objc static func startServices(initialConfig: ClientConfig) {
    let moduleConfig = ModuleConfig.defaultConfig()
    moduleConfig.initialConfig = initialConfig
    startServices(moduleConfig: moduleConfig)
  }
}

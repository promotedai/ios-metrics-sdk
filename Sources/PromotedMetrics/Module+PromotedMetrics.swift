import Foundation

#if !COCOAPODS
import PromotedCore
import PromotedFetcher
#endif

public extension Module {
  @objc public static func defaultConfig() -> ModuleConfig {
    let config = Self.coreConfig()
    config.useFetcher()
    return config
  }
}

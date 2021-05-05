import Foundation

#if !COCOAPODS
import PromotedCore
import PromotedFetcher
#endif

public extension ModuleConfig {
  @objc static func defaultConfig() -> ModuleConfig {
    let config = coreConfig()
    config.useFetcher()
    return config
  }
}

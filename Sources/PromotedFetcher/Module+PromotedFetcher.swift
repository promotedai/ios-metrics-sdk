import Foundation

#if !COCOAPODS
import PromotedCore
#endif

public extension Module {
  @objc public static func fetcherConfig() -> ModuleConfig {
    let config = Self.coreConfig()
    config.useFetcher()
    return config
  }

  @objc public func useFetcher() {
    networkConnection = GTMSessionFetcherConnection()
  }
}

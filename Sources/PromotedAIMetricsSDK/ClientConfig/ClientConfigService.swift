import Foundation

@objc(ClientConfigProvider)
public protocol ClientConfigProvider {
  func defaultConfig() -> ClientConfig
}

class ClientConfigService: NSObject {

  private var cachedConfig: ClientConfig?
  private weak var provider: ClientConfigProvider?

  /** Client configuration for this session. This will never change. */
  public var config: ClientConfig {
    if let result = cachedConfig { return result }
    return provider!.defaultConfig()
  }

  public init(provider: ClientConfigProvider) {
    super.init()
    self.cachedConfig = nil
    self.provider = provider
    
    // TODO: Stub always sets this to default config.
    // When we persist to disk, the user defaults should be the
    // first thing we try, then the default config.
    self.cachedConfig = provider.defaultConfig()
  }

  func fetchClientConfig() {
    // No-op for this stub version.
    // Make RPC call, then process config.
  }
}

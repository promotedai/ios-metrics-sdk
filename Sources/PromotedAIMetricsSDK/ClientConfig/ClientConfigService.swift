import Foundation

protocol ClientConfigDefaultProvider: class {
  var defaultConfig: ClientConfig { get }
}

class ClientConfigService: NSObject {

  private var cachedConfig: ClientConfig?
  private weak var provider: ClientConfigDefaultProvider?
  private weak var store: PersistentStore?

  /** Client configuration for this session. This will never change. */
  var config: ClientConfig {
    if let result = cachedConfig { return result }
    return provider!.defaultConfig
  }

  init(provider: ClientConfigDefaultProvider,
       store: PersistentStore) {
    super.init()
    self.cachedConfig = nil
    self.provider = provider
    self.store = store
    
    // TODO: Stub always sets this to default config.
    // When we persist to disk, the user defaults should be the
    // first thing we try, then the default config.
    self.cachedConfig = provider.defaultConfig
  }

  func fetchClientConfig() {
    // No-op for this stub version.
    // Make RPC call, then process config.
  }
}

import Foundation

// MARK: - ClientConfigListener
public protocol ClientConfigListener: class {
  func clientConfigDidChange(_ config: ClientConfig)
}

// MARK: - ClientConfigService
/**
 Provides `ClientConfig` from some arbitrary source.
 
 The config is always accessible during the service's lifetime,
 but may change depending on when it is accessed. Such changes
 may occur only in the following situations, and there will be at
 most 2 changes:
 
 1. The locally cached configuration is loaded from disk, or
 2. The remote configuration is fetched.
 
 Use `addClientConfigListener` to receive updates when client config
 changes. If you don't need to react immediately to changes, you can
 simply read from the `ClientConfig` object each time you need to access
 a config property. `ClientConfig` objects 
 */
public protocol ClientConfigService {
  
  /// The current config for the session. May change when different
  /// configs load.
  var config: ClientConfig { get }
  func addClientConfigListener(_ listener: ClientConfigListener)
  func removeClientConfigListener(_ listener: ClientConfigListener)
  func fetchClientConfig()
}

// MARK: - ClientConfigService
/** DO NOT INSTANTIATE. Base class for ClientConfigService. */
open class AbstractClientConfigService: ClientConfigService {

  public private(set) var config: ClientConfig
  public let initialConfig: ClientConfig

  private var listeners: [ClientConfigListener]

  public init(initialConfig: ClientConfig) {
    self.config = initialConfig
    self.initialConfig = initialConfig
    self.listeners = []
  }
  
  public func addClientConfigListener(_ listener: ClientConfigListener) {
    listeners.append(listener)
  }
  
  public func removeClientConfigListener(_ listener: ClientConfigListener) {
    listeners.removeAll(where: { $0 === listener })
  }

  open func fetchClientConfig() {
    assertionFailure("Don't instantiate ClientConfigService")
  }
}

// MARK: - Subclassing
public extension AbstractClientConfigService {
  func setClientConfigAndNotifyListeners(_ config: ClientConfig) {
    self.config = config
    for l in listeners {
      l.clientConfigDidChange(config)
    }
  }
}

// MARK: - LocalClientConfigService
/** Loads from local device. */
public class LocalClientConfigService: AbstractClientConfigService {
  public override func fetchClientConfig() {
    // No-op for local config.
  }
}

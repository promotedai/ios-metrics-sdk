import Foundation

// MARK: - ClientConfigListener
public protocol ClientConfigListener: class {
  func clientConfigDidChange(_ config: ClientConfig)
}

// MARK: - ClientConfigService
/**
 Provides `ClientConfig` from some arbitrary source. The config
 is always accessible during the service's lifetime, but may change
 depending on when it is accessed.
 */
public protocol ClientConfigService {
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
public class LocalClientConfigService: AbstractClientConfigService {
  public override func fetchClientConfig() {
    // No-op for local config.
  }
}

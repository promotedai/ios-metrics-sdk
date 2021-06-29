import Foundation

// MARK: - ClientConfigListener
/** Listens for changes when `ClientConfig` loads. */
public protocol ClientConfigListener: AnyObject {
  func clientConfigDidChange(_ config: ClientConfig)
}

// MARK: - ClientConfigServiceFetchStatus

/** Status of loading client config. */
public enum ClientConfigServiceFetchStatus {
  case pending
  case inProgress(cachedAvailable: Bool)
  case success
  case failure(error: Error, cachedAvailable: Bool)
}

// MARK: - ClientConfigService

/**
 Provides `ClientConfig` from some arbitrary source.
 
 The config is always accessible during the service's lifetime,
 but its values may change depending on when it is accessed. Such
 changes may occur only in the following situations:
 
 1. The locally cached configuration is loaded from disk, or
 2. The remote configuration is fetched.
 
 Use `addClientConfigListener` to receive updates when client config
 changes. If you don't need to react immediately to changes, you can
 simply read from the `ClientConfig` object each time you need to access
 a config property.
 */
public protocol ClientConfigService: AnyObject {

  typealias FetchStatus = ClientConfigServiceFetchStatus

  /// Status of this service.
  var fetchStatus: FetchStatus { get }
  
  /// The current config for the session. May change when different
  /// configs load.
  var config: ClientConfig { get }

  /// Adds a listener to be notified when the config changes.
  func addClientConfigListener(_ listener: ClientConfigListener)
  
  /// Removes a listener.
  func removeClientConfigListener(_ listener: ClientConfigListener)

  typealias Callback = (ClientConfig?, Error?) throws -> Void

  /// Initiates asynchronous load of client properties.
  func fetchClientConfig(initialConfig: ClientConfig,
                         callback: @escaping Callback) rethrows
}

protocol InternalClientConfigService: ClientConfigService {
  typealias FetchDeps = InitialConfigSource & PersistentStoreSource
  func fetchClientConfig(deps: FetchDeps,
                         callback: @escaping Callback) rethrows
}

protocol ClientConfigServiceSource {
  var clientConfigService: ClientConfigService { get }
}

// MARK: - CachingClientConfigService
/**
 Base implementation of service that caches results to load locally
 while waiting for remote. Typically, this class will
 */
open class CachingClientConfigService: InternalClientConfigService {

  public private(set) var config: ClientConfig

  public private(set) var fetchStatus: FetchStatus

  fileprivate var listeners: WeakArray<ClientConfigListener>

  public init() {
    self.listeners = []
    self.fetchStatus = .pending
    self.config = ClientConfig()
  }

  public func addClientConfigListener(_ listener: ClientConfigListener) {
    listeners.append(listener)
  }

  public func removeClientConfigListener(_ listener: ClientConfigListener) {
    listeners.removeAll(identicalTo: listener)
  }

  func fetchClientConfig(deps: FetchDeps,
                         callback: @escaping Callback) rethrows {
    let initialConfig = deps.initialConfig
    let store = deps.persistentStore
    fetchStatus = .inProgress(cachedAvailable: false)

    // This loads the cached config synchronously.
    if let clientConfigDict = store.clientConfig {
      var warnings: [String]? = []
      var infos: [String]? = []
      config = ClientConfig(dictionary: clientConfigDict, warnings: &warnings, infos: &infos)
      fetchStatus = .inProgress(cachedAvailable: true)
    }

    try fetchClientConfig(initialConfig: initialConfig) {
      [weak self] (config, error) in
      guard let self = self else { return }
      let cachedAvailable = self.fetchStatus.cachedAvailable

      if let error = error {
        let e = ClientConfigError.remoteConfigFetchError(error)
        self.fetchStatus = .failure(error: e, cachedAvailable: cachedAvailable)
        try callback(nil, e)
        return
      }

      if let config = config {
        self.fetchStatus = .success
        store.clientConfig = config.asDictionary()
        try callback(config, nil)
        return
      }

      let e = ClientConfigError.emptyRemoteConfig
      self.fetchStatus = .failure(error: e, cachedAvailable: cachedAvailable)
      try callback(nil, e)
    }
  }

  open func fetchClientConfig(initialConfig: ClientConfig,
                              callback: @escaping Callback) rethrows {
    try callback(initialConfig, nil)
  }
}

// MARK: - ClientConfigServiceFetchStatus extension
extension ClientConfigServiceFetchStatus {
  var cachedAvailable: Bool {
    switch self {
    case .pending:
      return false
    case .success:
      return true
    case .inProgress(let cachedAvailable),
         .failure(_, let cachedAvailable):
      return cachedAvailable
    }
  }
}

extension ClientConfigServiceFetchStatus: Equatable {
  public static func == (lhs: ClientConfigServiceFetchStatus,
                         rhs: ClientConfigServiceFetchStatus) -> Bool {
    switch (lhs, rhs) {
    case (.pending, .pending),
         (.success, .success):
      return true
    case (.inProgress(let lhsCachedAvailable),
          .inProgress(let rhsCachedAvailable)),
         // TODO: We're discarding the error for now.
         (.failure(_, let lhsCachedAvailable),
          .failure(_, let rhsCachedAvailable)):
      return (lhsCachedAvailable == rhsCachedAvailable)
    default:
      return false
    }
  }
}

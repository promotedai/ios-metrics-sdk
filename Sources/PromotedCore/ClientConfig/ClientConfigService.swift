import Foundation

// MARK: - ClientConfigService

/**
 Provides `ClientConfig` for this logging session.
 
 This config may be loaded from the following sources:
 
 1. The `initialConfig` with hard-coded values provided via
    logging startup code. This is used on first startup and
    in cases where reading cached/remote configs fail.
 2. Cached config on disk. When a remote config is successfully
    fetched, it is stored locally and read on the next startup
    of the logging system. (The first startup uses the hard-coded
    `initialConfig` values.) Cached config values take precedence
    over hard-coded ones.
 3. Remotely over the network. When a remote config is successfully
    fetched, it overwrites any existing cached configs. Remote
    config loads only happen if `RemoteConfigConnection` is provided.
 */
final class ClientConfigService: AnyObject {

  /** Status of loading client config. */
  enum FetchStatus {
    case pending
    case inProgress(cachedAvailable: Bool)
    case success
    case failure(error: Error, cachedAvailable: Bool)
  }
  /// Status of this service.
  private(set) var fetchStatus: FetchStatus
  
  /// The current config for the session.
  var config: ClientConfig {
    assert(fetchStatus.cachedAvailable)
    return cachedConfig
  }

  private var cachedConfig: ClientConfig

  private let remoteConfigConnection: RemoteConfigConnection?

  init(remoteConfigConnection: RemoteConfigConnection?) {
    self.fetchStatus = .pending
    self.config = ClientConfig()
    self.remoteConfigConnection = remoteConfigConnection
  }

}

protocol ClientConfigServiceSource {
  var clientConfigService: ClientConfigService { get }
}

extension ClientConfigService {

  typealias FetchDeps = InitialConfigSource & PersistentStoreSource
  typealias Callback = (ClientConfig?, Error?) throws -> Void

  /// Loads cached config synchronously and initiates asynchronous
  /// load of remote config (for use in next startup).
  func fetchClientConfig(deps: FetchDeps,
                         callback: @escaping Callback) rethrows {
    let initialConfig = deps.initialConfig
    let store = deps.persistentStore
    fetchStatus = .inProgress(cachedAvailable: false)

    // This loads the cached config synchronously.
    if let clientConfigDict = store.clientConfig {
      var warnings: [String]? = []
      var infos: [String]? = []
      let config = ClientConfig(initialConfig)
      config.merge(from: clientConfigDict, warnings: &warnings, infos: &infos)
      cachedConfig = config
      fetchStatus = .inProgress(cachedAvailable: true)
    }

    try remoteConfigConnection?.fetchClientConfig(initialConfig: initialConfig) {
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

extension ClientConfigService.FetchStatus {
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

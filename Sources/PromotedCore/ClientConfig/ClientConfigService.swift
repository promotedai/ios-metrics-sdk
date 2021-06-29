import Foundation

// MARK: - ClientConfigService

/**
 Provides `ClientConfig` for this logging session.
 Remote config loads only happen if `RemoteConfigConnection`
 is provided.

 This config may be loaded from the following sources:
 
 1. The `initialConfig` with hard-coded values provided via
    logging startup code. This is used on first startup and
    in cases where reading cached/remote configs fail.
 2. Cached config on disk. When a remote config is successfully
    fetched, it is stored locally and read on the next startup
    of the logging system. (The first startup uses the hard-coded
    `initialConfig` values.) Cached config values take precedence
    over hard-coded ones. A cached config will only exist when
    a remote config load succeeds.
 3. Remotely over the network. When a remote config is
    successfully fetched, it overwrites any existing cached
    configs. The `config` property as observed in this class will
    never take on the value of a remotely-loaded config that was
    loaded in the current session.
 */
final class ClientConfigService: AnyObject {

  /** Source of client config. */
  enum ConfigSource: Equatable {
    /// The initial config provided via hard-coded
    /// initialization of the logging library.
    case initial
    /// Locally cached config provided by remote source
    /// during the previous session.
    case localCache
  }
  /// Source of client config.
  private(set) var source: ConfigSource

  /// The current config for the session.
  private(set) var config: ClientConfig

  private let initialConfig: ClientConfig
  private unowned let store: PersistentStore
  private unowned let remoteConfigConnection: RemoteConfigConnection?

  /// Available before `ClientConfig` loads. If you're working
  /// in a class that is a dependency of `ClientConfigService`
  /// then you can only pull in these dependencies. Be careful
  /// modifying this, so that you don't accidentally pull in
  /// something that depends on `ClientConfig`.
  typealias Deps = InitialConfigSource & PersistentStoreSource &
                   RemoteConfigConnectionSource

  init(deps: Deps) {
    self.initialConfig = deps.initialConfig
    self.store = deps.persistentStore
    self.remoteConfigConnection = deps.remoteConfigConnection
    self.source = .initial
    self.config = ClientConfig(deps.initialConfig)
  }
}

protocol ClientConfigServiceSource {
  var clientConfigService: ClientConfigService { get }
}

extension ClientConfigService {

  typealias Callback = (ClientConfig?, Error?) -> Void

  /// Loads cached config synchronously and initiates asynchronous
  /// load of remote config (for use in next startup).
  func fetchClientConfig(callback: @escaping Callback? = nil) throws {
    // This loads the cached config synchronously.
    if let clientConfigDict = store.clientConfig {
      var warnings: [String]? = []
      var infos: [String]? = []
      let config = ClientConfig(initialConfig)
      config.merge(from: clientConfigDict, warnings: &warnings, infos: &infos)
      self.config = config
      self.source = .localCache
    }

    try remoteConfigConnection?.fetchClientConfig(initialConfig: initialConfig) {
      [weak self] (config, error) in
      guard let self = self else { return }

      // If any error loading remote config, bail.
      if let error = error {
        let e = ClientConfigError.remoteConfigFetchError(error)
        callback?(nil, e)
        return
      }

      // Successfully loaded config. Save for next session.
      if let config = config {
        self.store.clientConfig = config.asDictionary()
        callback?(config, nil)
        return
      }

      // Somehow failed to get error or config.
      let e = ClientConfigError.emptyRemoteConfig
      callback?(nil, e)
    }
  }
}

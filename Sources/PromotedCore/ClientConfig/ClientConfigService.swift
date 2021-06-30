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
final class ClientConfigService {

  /// The current config for the session.
  var config: ClientConfig {
    assert(wasConfigFetched, "Attempt to access config before fetchClientConfig")
    return _config
  }
  private var _config: ClientConfig
  private var wasConfigFetched: Bool

  private let initialConfig: ClientConfig
  private unowned let store: PersistentStore
  private unowned let remoteConfigConnection: RemoteConfigConnection?

  /// Warnings that occurred during fetch.
  /// After initialization, these can be logged.
  private(set) var fetchWarnings: [String]

  /// Info messages that occurred during fetch.
  /// After initialization, these can be logged.
  private(set) var fetchInfos: [String]

  /// Available before `ClientConfig` loads. If you're working
  /// in a class that is a dependency of `ClientConfigService`
  /// then you can only pull in these dependencies. Be careful
  /// modifying this, so that you don't accidentally pull in
  /// something that depends on `ClientConfig`.
  typealias Deps = (InitialConfigSource &
                    PersistentStoreSource &
                    RemoteConfigConnectionSource)

  init(deps: Deps) {
    self._config = ClientConfig(deps.initialConfig)
    self.wasConfigFetched = false
    self.initialConfig = ClientConfig(deps.initialConfig)
    self.store = deps.persistentStore
    self.remoteConfigConnection = deps.remoteConfigConnection
    self.fetchWarnings = []
    self.fetchInfos = []
  }
}

protocol ClientConfigServiceSource: ClientConfigService.Deps {
  var clientConfigService: ClientConfigService { get }
}

extension ClientConfigService {

  typealias Callback = (ClientConfig?, Error?) -> Void

  /// Loads cached config synchronously and initiates asynchronous
  /// load of remote config (for use in next startup).
  func fetchClientConfig(callback: Callback? = nil) throws {
    // This loads the cached config synchronously.
    if let clientConfigDict = store.clientConfig {
      _config.merge(
        from: clientConfigDict,
        warnings: &fetchWarnings,
        infos: &fetchInfos
      )
    }
    wasConfigFetched = true

    try remoteConfigConnection?.fetchClientConfig(
      initialConfig: initialConfig
    ) {
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
        self.store.clientConfig = config.asDictionary(
          warnings: &self.fetchWarnings
        )
        callback?(config, nil)
        return
      }

      // Somehow failed to get error or config.
      let e = ClientConfigError.emptyRemoteConfig
      callback?(nil, e)
    }
  }
}

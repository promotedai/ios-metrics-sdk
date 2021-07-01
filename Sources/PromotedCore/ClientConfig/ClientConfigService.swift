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
  }
}

protocol ClientConfigServiceSource: ClientConfigService.Deps {
  var clientConfigService: ClientConfigService { get }
}

extension ClientConfigService {

  struct Result {
    let config: ClientConfig?
    let error: ClientConfigError?
    let messages: PendingLogMessages
  }

  typealias Callback = (Result) -> Void

  /// Loads cached config synchronously and initiates asynchronous
  /// load of remote config (for use in next startup).
  func fetchClientConfig(callback: Callback? = nil) throws {
    // This loads the cached config synchronously.
    if let clientConfigData = store.clientConfig {
      let decoder = JSONDecoder()
      _config = try decoder.decode(
        ClientConfig.self, from: clientConfigData
      )
    }
    wasConfigFetched = true

    // Use initialConfig as the basis of the fetch so that
    // incremental changes are applied to this baseline.
    try remoteConfigConnection?.fetchClientConfig(
      initialConfig: initialConfig
    ) {
      [weak self] remoteResult in
      guard let self = self else { return }

      var resultConfig: ClientConfig? = nil
      var resultError: ClientConfigError? = nil
      defer {
        if let callback = callback {
          let result = Result(
            config: resultConfig,
            error: resultError,
            messages: remoteResult.messages
          )
          callback(result)
        }
      }

      if let remoteError = remoteResult.error {
        resultError = .remoteConfigFetchError(remoteError)
        return
      }

      guard let remoteConfig = remoteResult.config else {
        // Somehow failed to get error or config.
        resultError = .emptyRemoteConfig
        return
      }

      // Successfully loaded config. Save for next session.
      let encoder = JSONEncoder()
      do {
        self.store.clientConfig = try encoder.encode(remoteConfig)
        resultConfig = remoteConfig
      } catch {
        resultError = .localCacheEncodeError(error)
      }
    }
  }
}

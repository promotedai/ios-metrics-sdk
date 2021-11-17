import Foundation

// MARK: - ClientConfigService

/**
 Loads `ClientConfig` for this logging session.
 Remote config loads only happen if `RemoteConfigConnection`
 is provided. When a remote config is loaded, it is applied on
 the **next** startup, not the current session.

 The `ClientConfig` may be loaded from the following sources:

 1. The `initialConfig` with hard-coded values provided via
    logging startup code. This is used on first startup and
    when we don't load cached/remote configs.
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

 If any errors are encountered, the most recent value of `config`
 is used for the remainder of the session:

 - If an error occurs when decoding local cached config, then
   `initialConfig` is used for the session.
 - If an error occurs during remote fetch, then no local cached
   copy is made, and the existing `config` is used for the
   session (just as it would have been).
 */
final class ClientConfigService {

  /// The current config for the session.
  var config: ClientConfig {
    assert(
      wasConfigFetched,
      "Attempt to access config before fetchClientConfig"
    )
    return _config
  }
  private var _config: ClientConfig
  private var wasConfigFetched: Bool

  private unowned let clock: Clock
  private let initialConfig: ClientConfig
  private unowned let store: PersistentStore
  private unowned let remoteConfigConnection: RemoteConfigConnection?

  /// Available before `ClientConfig` loads. If you're working
  /// in a class that is a dependency of `ClientConfigService`
  /// then you can only pull in these dependencies. Be careful
  /// modifying this, so that you don't accidentally pull in
  /// something that depends on `ClientConfig`.
  typealias Deps = (
    ClockSource &
    InitialConfigSource &
    PersistentStoreSource &
    RemoteConfigConnectionSource
  )

  init(deps: Deps) {
    self._config = deps.initialConfig
    self.wasConfigFetched = false
    self.clock = deps.clock
    self.initialConfig = deps.initialConfig
    self.store = deps.persistentStore
    self.remoteConfigConnection = deps.remoteConfigConnection
  }
}

protocol ClientConfigServiceSource {
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
  func fetchClientConfig(callback: @escaping Callback) {

    // This loads the cached config synchronously.
    var fetchMessages = PendingLogMessages()
    loadLocalCachedConfig(fetchMessages: &fetchMessages)
    wasConfigFetched = true

    guard let connection = remoteConfigConnection else {
      handleRemoteConfigUnavailable(
        callback: callback,
        fetchMessages: &fetchMessages
      )
      return
    }

    fetchMessages.info(
      "Scheduling remote config fetch in 5 seconds.",
      visibility: .public
    )

    _ = clock.schedule(timeInterval: 5.0) { [weak self] _ in
      guard let self = self else { return }
      // Use initialConfig as the basis of the fetch so that
      // incremental changes are applied to this baseline.
      connection.fetchClientConfig(
        initialConfig: self.initialConfig
      ) { remoteResult in
        self.handleRemoteConfigFetchComplete(
          remoteResult: remoteResult,
          callback: callback,
          fetchMessages: &fetchMessages
        )
      }
    }
  }

  private func loadLocalCachedConfig(
    fetchMessages: inout PendingLogMessages
  ) {
    if let clientConfigData = store.clientConfig {
      do {
        let decoder = JSONDecoder()
        _config = try decoder.decode(
          ClientConfig.self, from: clientConfigData
        )
        fetchMessages.info(
          "Local cached config successfully applied.",
          visibility: .public
        )
      } catch {
        // Prevent error from happening again next startup.
        store.clientConfig = nil
        fetchMessages.error(
          "Local cached config failed to apply: \(String(describing: error)) " +
            "Falling back to initial config.",
          visibility: .public
        )
      }
    } else {
      fetchMessages.info(
        "Local cached config not found. Skipping.",
        visibility: .public
      )
    }
  }

  private func handleRemoteConfigUnavailable(
    callback: Callback,
    fetchMessages: inout PendingLogMessages
  ) {
    fetchMessages.info(
      "Remote config not configured. Skipping.",
      visibility: .public
    )
    let result = Result(
      config: _config,
      error: nil,
      messages: fetchMessages
    )
    callback(result)
  }

  private func handleRemoteConfigFetchComplete(
    remoteResult: RemoteConfigConnection.Result,
    callback: Callback,
    fetchMessages: inout PendingLogMessages
  ) {
    var resultConfig: ClientConfig? = nil
    var resultError: ClientConfigError? = nil
    var resultMessages = fetchMessages + remoteResult.messages
    defer {
      let result = Result(
        config: resultConfig,
        error: resultError,
        messages: resultMessages
      )
      callback(result)
    }

    fetchMessages.info(
      "Remote config fetch starting.",
      visibility: .public
    )

    guard remoteResult.error == nil else {
      resultError = .remoteConfigFetchError(remoteResult.error!)
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
      resultMessages.info(
        "Remote config successfully cached.",
        visibility: .public
      )
    } catch {
      resultError = .localCacheEncodeError(error)
    }
  }
}

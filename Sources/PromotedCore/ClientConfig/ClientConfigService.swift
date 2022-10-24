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
    return cachedConfig
  }
  private var cachedConfig: ClientConfig
  private var wasConfigFetched: Bool

  private unowned let clock: Clock
  private let initialConfig: ClientConfig
  private unowned let deviceInfo: DeviceInfo
  private unowned let store: PersistentStore
  private unowned let remoteConfigConnection: RemoteConfigConnection?

  /// Available before `ClientConfig` loads. If you're working
  /// in a class that is a dependency of `ClientConfigService`
  /// then you can only pull in these dependencies. Be careful
  /// modifying this, so that you don't accidentally pull in
  /// something that depends on `ClientConfig`.
  typealias Deps = (
    ClockSource &
    DeviceInfoSource &
    InitialConfigSource &
    PersistentStoreSource &
    RemoteConfigConnectionSource
  )

  init(deps: Deps) {
    self.cachedConfig = deps.initialConfig
    self.wasConfigFetched = false
    self.clock = deps.clock
    self.initialConfig = deps.initialConfig
    self.deviceInfo = deps.deviceInfo
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
    let error: ClientConfigFetchError?
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

    clock.schedule(timeInterval: 5.0) { [weak self] _ in
      guard let self = self else { return }
      do {
        fetchMessages.info(
          "Remote config fetch starting.",
          visibility: .public
        )
        // Use initialConfig as the basis of the fetch so that
        // incremental changes are applied to this baseline.
        try connection.fetchClientConfig(
          initialConfig: self.initialConfig
        ) { remoteResult in
          self.handleRemoteConfigFetchComplete(
            remoteResult: remoteResult,
            callback: callback,
            fetchMessages: fetchMessages
          )
        }
      } catch {
        self.handleRemoteConfigFetchError(
          error,
          callback: callback,
          fetchMessages: fetchMessages
        )
      }
    }
  }

  private func loadLocalCachedConfig(
    fetchMessages: inout PendingLogMessages
  ) {
    guard let clientConfigData = store.clientConfig else {
      fetchMessages.info(
        "Local cached config not found. Skipping.",
        visibility: .public
      )
      return
    }
    do {
      let decoder = JSONDecoder()
      cachedConfig = try decoder.decode(
        ClientConfig.self,
        from: clientConfigData
      )
      fetchMessages.info(
        "Local cached config successfully applied.",
        visibility: .public
      )
    } catch {
      // Prevent error from happening again next startup.
      store.clientConfig = nil
      fetchMessages.error(
        "Local cached config failed to apply: " +
          "\(String(describing: error)). " +
          "Falling back to initial config.",
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
    cachedConfig = applyDiagnosticsSamplingIfNeeded(
      cachedConfig,
      messages: &fetchMessages
    )
    let result = Result(
      config: cachedConfig,
      error: nil,
      messages: fetchMessages
    )
    callback(result)
  }

  private func applyDiagnosticsSamplingIfNeeded(
    _ config: ClientConfig,
    messages: inout PendingLogMessages
  ) -> ClientConfig {
    let percentage = config.diagnosticsSamplingPercentage
    guard percentage > 0 else { return config }
    guard let endDate = config.diagnosticsSamplingEndDate else {
      messages.warning(
        "Config specifies diagnosticsSamplingPercentage=\(percentage)% " +
        "but no end date. Ignoring.",
        visibility: .public
      )
      return config
    }
    let now = clock.now
    let endTime = endDate.timeIntervalSince1970
    guard clock.now < endTime else {
      messages.info(
        "Config specifies diagnosticsSamplingPercentage=\(percentage)% " +
        "and end date (\(endTime.asFormattedDateStringSince1970())) " +
        "earlier than or equal to current date " +
        "(\(now.asFormattedDateStringSince1970())). Skipping.",
        visibility: .public
      )
      return config
    }
    guard shouldSampleDiagnostics(percentage: percentage) else {
      messages.info(
        "Config specifies diagnosticsSamplingPercentage=\(percentage)% " +
        "and end date (\(endTime.asFormattedDateStringSince1970())) " +
        "but random sample skipped.",
        visibility: .public
      )
      return config
    }
    messages.info(
      "Config specifies diagnosticsSamplingPercentage=\(percentage)% " +
      "and end date (\(endTime.asFormattedDateStringSince1970())). " +
      "Enabling all diagnostics.",
      visibility: .public
    )
    var configCopy = config
    configCopy.setAllDiagnosticsEnabled(true)
    return configCopy
  }

  private func shouldSampleDiagnostics(percentage: Int) -> Bool {
    let uuid = (
      UUID(uuidString: store.logUserID ?? "") ??
      deviceInfo.identifierForVendor ??
      UUID()
    )
    return uuid.stableHashValue(mod: 100) < percentage
  }

  private func handleRemoteConfigFetchComplete(
    remoteResult: RemoteConfigConnection.Result,
    callback: Callback,
    fetchMessages: PendingLogMessages
  ) {
    var resultConfig: ClientConfig? = nil
    var resultError: ClientConfigFetchError? = nil
    var resultMessages = fetchMessages + remoteResult.messages
    defer {
      let result = Result(
        config: resultConfig,
        error: resultError,
        messages: resultMessages
      )
      callback(result)
    }

    guard remoteResult.error == nil else {
      resultError = .networkError(remoteResult.error!)
      return
    }

    guard let remoteConfig = remoteResult.config else {
      // Somehow failed to get error or config.
      resultError = .emptyConfig
      return
    }

    do {
      // Ensure that the resulting config is valid.
      try remoteConfig.validateConfig()
    } catch {
      resultError = .invalidConfig(error)
      return
    }

    // Successfully loaded config. Save for next session.
    do {
      let encoder = JSONEncoder()
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

  private func handleRemoteConfigFetchError(
    _ error: Error,
    callback: Callback,
    fetchMessages: PendingLogMessages
  ) {
    var resultMessages = fetchMessages
    resultMessages.warning(
      "Remote config fetch failed. Using local cached config.",
      visibility: .public
    )
    let result = Result(
      config: cachedConfig,
      error: .networkError(error),
      messages: resultMessages
    )
    callback(result)
  }
}

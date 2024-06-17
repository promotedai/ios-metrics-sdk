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

  private(set) static var fetchLogMessages = PendingLogMessages()

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
  private var fetchLogMessages: PendingLogMessages

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

  init(deps: Deps, fetchLogMessages: PendingLogMessages? = nil) {
    self.cachedConfig = deps.initialConfig
    self.wasConfigFetched = false
    self.fetchLogMessages = fetchLogMessages ?? Self.fetchLogMessages
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

  /// Loads cached config synchronously and initiates asynchronous
  /// load of remote config (for use in next startup).
  func fetchClientConfig() async throws -> ClientConfig {
    // This loads the cached config synchronously.
    loadLocalCachedConfig()
    wasConfigFetched = true

    guard let connection = remoteConfigConnection else {
      fetchLogMessages.info(
        "Remote config not configured. Skipping.",
        visibility: .public
      )
      return applyDiagnosticsSamplingIfNeeded(cachedConfig)
    }

    fetchLogMessages.info(
      "Scheduling remote config fetch in 5 seconds.",
      visibility: .public
    )

    do {
      try await clock.sleep(duration: .seconds(5))
    } catch is CancellationError {
      fetchLogMessages.warning(
        "Interrupted. Using local cached config.",
        visibility: .public
      )
      return cachedConfig
    }

    fetchLogMessages.info(
      "Remote config fetch starting.",
      visibility: .public
    )

    let remoteConfig: ClientConfig
    do {
      // Use initialConfig as the basis of the fetch so that
      // incremental changes are applied to this baseline.
      remoteConfig = try await connection.fetchClientConfig(
        initialConfig: self.initialConfig
      )
      try remoteConfig.validateConfig()
    } catch is ClientConfigError {
      fetchLogMessages.warning(
        "Remote config validation failed. Using local cached config.",
        visibility: .public
      )
      return cachedConfig
    } catch {
      fetchLogMessages.warning(
        "Remote config fetch failed. Using local cached config.",
        visibility: .public
      )
      return cachedConfig
    }

    do {
      try cacheRemoteConfig(remoteConfig)
    } catch {
      fetchLogMessages.warning(
        "Remote config cache failed. Using local cached config.",
        visibility: .public
      )
    }

    return remoteConfig
  }

  private func loadLocalCachedConfig() {
    guard let clientConfigData = store.clientConfig else {
      fetchLogMessages.info(
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
      fetchLogMessages.info(
        "Local cached config successfully applied.",
        visibility: .public
      )
    } catch {
      // Prevent error from happening again next startup.
      store.clientConfig = nil
      fetchLogMessages.error(
        "Local cached config failed to apply: " +
          "\(String(describing: error)). " +
          "Falling back to initial config.",
        visibility: .public
      )
    }
  }

  private func configForRemoteConfigUnavailable() -> ClientConfig{
    fetchLogMessages.info(
      "Remote config not configured. Skipping.",
      visibility: .public
    )
    cachedConfig = applyDiagnosticsSamplingIfNeeded(
      cachedConfig
    )
    return cachedConfig
  }

  private func applyDiagnosticsSamplingIfNeeded(
    _ config: ClientConfig
  ) -> ClientConfig {
    let percentage = config.diagnosticsSamplingPercentage
    guard percentage > 0 else { return config }
    guard let endDate = config.diagnosticsSamplingEndDate else {
      fetchLogMessages.warning(
        "Config specifies diagnosticsSamplingPercentage=\(percentage)% " +
        "but no end date. Ignoring.",
        visibility: .public
      )
      return config
    }
    let now = clock.now
    let endTime = endDate.timeIntervalSince1970
    guard clock.now < endTime else {
      fetchLogMessages.info(
        "Config specifies diagnosticsSamplingPercentage=\(percentage)% " +
        "and end date (\(endTime.asFormattedDateStringSince1970())) " +
        "earlier than or equal to current date " +
        "(\(now.asFormattedDateStringSince1970())). Skipping.",
        visibility: .public
      )
      return config
    }
    guard shouldSampleDiagnostics(percentage: percentage) else {
      fetchLogMessages.info(
        "Config specifies diagnosticsSamplingPercentage=\(percentage)% " +
        "and end date (\(endTime.asFormattedDateStringSince1970())) " +
        "but random sample skipped.",
        visibility: .public
      )
      return config
    }
    fetchLogMessages.info(
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

  private func cacheRemoteConfig(_ remoteConfig: ClientConfig) throws {
    // Successfully loaded config. Save for next session.
    do {
      let encoder = JSONEncoder()
      self.store.clientConfig = try encoder.encode(remoteConfig)
      fetchLogMessages.info(
        "Remote config successfully cached.",
        visibility: .public
      )
    } catch {
      throw ClientConfigFetchError.localCacheEncodeError(error)
    }
  }
}

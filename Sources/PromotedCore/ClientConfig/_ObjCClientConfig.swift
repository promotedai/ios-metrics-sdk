import Foundation

/// Enumeration value in config.
public protocol ConfigEnum:
  CaseIterable,
  Codable,
  CustomStringConvertible,
  Equatable,
  RawRepresentable {}

/**
 See `ClientConfig`. This class exists only for compatibility
 with Objective C. Do not use from Swift.

 Add new config properties in this class.

 # Adding new properties.

 When adding a new property, do the following:

 1. Add the property in this class.
 2. Ensure the type is `Codable` and can be expressed in
    Objective C.
 3. Make the property `@objc`.

 # Adding new enums

 When adding a new enum property, do the following:

 1. Add the type in this class.
 2. Make the type `@objc` and prefix its name with `PRO`.
 3. Add a `typealias` to your type in `ClientConfig`. Swift
    code should only refer to the type in `ClientConfig`.
 4. Make it an `Int` enum.
 5. Give it a case with value 0, and make that case the default
    value, or at least a harmless value. This is because any
    invalid values for the enum will be evaluated to the raw
    value of 0.
 6. Make it conform to `ConfigEnum`.
 7. Add an extension that contains `var description`.
 8. Add the enum to `value()` and `setValue()` workarounds.

 The final three items ensure that it works with remote config
 and serialization.

 Example:
 ```swift
 @objc(PROAlohaEnum)
 public enum AlohaEnum: Int, ConfigEnum {
   case hello = 0
   case goodbye = 1
 }
 @objc public var aloha: AlohaEnum = .hello

 extension ClientConfig.AlohaEnum {
   public var description: String {
     switch self {
     case .hello:
       return "hello"
     case .goodbye:
       return "goodbye"
     default:
       return "unknown"
   }
 }
 ```

 # Validation

 When adding new properties that are numerical or enum values,
 make sure to validate in `didSet` to ensure that incorrect
 values don't cause unreasonable behavior during runtime. See
 `bound` and `validateEnum`.
 */
@objc(PROClientConfig)
public final class _ObjCClientConfig: NSObject {

  /// Controls whether log messages are sent over the network.
  /// Setting this property to `false` will prevent log messages
  /// from being sent, but these messages may still be collected
  /// at runtime and stored in memory.
  @objc public var loggingEnabled: Bool = true

  /// URL for logging endpoint as used by `NetworkConnection`.
  /// Implementations of `NetworkConnection` from Promoted will
  /// use this field. Custom implementations of `NetworkConnection`
  /// may vary in behavior.
  @objc public var metricsLoggingURL: String = ""

  /// URL for logging endpoint as used by `NetworkConnection`
  /// for debug/staging purposes. Used when the app is running
  /// in debug configuration.
  ///
  /// If this property is not set, then debug builds will use
  /// `metricsLoggingURL` for logging endpoint URL.
  ///
  /// Implementations of `NetworkConnection` from Promoted will
  /// use this field. Custom implementations of `NetworkConnection`
  /// may vary in behavior.
  @objc public var devMetricsLoggingURL: String = ""

  /// API key for logging endpoint.
  /// Implementations of `NetworkConnection` from Promoted will
  /// use this field. Custom implementations of `NetworkConnection`
  /// may vary in behavior.
  @objc public var metricsLoggingAPIKey: String = ""

  /// API key for logging endpoint for debug/staging purposes.
  /// Used when the app is running in debug configuration.
  ///
  /// If this property is not set, then debug builds will use
  /// `metricsLoggingAPIKey` for logging endpoint API key.
  ///
  /// Implementations of `NetworkConnection` from Promoted will
  /// use this field. Custom implementations of `NetworkConnection`
  /// may vary in behavior.
  @objc public var devMetricsLoggingAPIKey: String = ""

  /// HTTP header field for API key.
  @objc public var apiKeyHTTPHeaderField: String = "x-api-key"

  /// Format to use when sending protobuf log messages over network.
  @objc(PROMetricsLoggingWireFormat)
  public enum MetricsLoggingWireFormat: Int, ConfigEnum {
    /// https://developers.google.com/protocol-buffers/docs/encoding
    case binary = 0
    /// https://developers.google.com/protocol-buffers/docs/proto3#json
    case json = 1
  }
  /// Format to use when sending protobuf log messages over network.
  @objc public var metricsLoggingWireFormat:
    MetricsLoggingWireFormat = .binary
  {
    didSet { validateEnum(&metricsLoggingWireFormat, defaultValue: .binary) }
  }

  /// Interval at which log messages are sent over the network.
  /// Setting this to lower values will increase the frequency
  /// at which log messages are sent.
  @objc public var loggingFlushInterval: TimeInterval = 10.0 {
    didSet { bound(&loggingFlushInterval, min: 1.0, max: 300.0) }
  }

  /// Whether to automatically flush all pending log messages
  /// when the application resigns active.
  @objc public var flushLoggingOnResignActive: Bool = true

  /// Ratio of the view that must be visible to log impression
  /// with `ScrollTracker`.
  @objc public var scrollTrackerVisibilityThreshold: Float = 0.5 {
    didSet { bound(&scrollTrackerVisibilityThreshold, min: 0.0, max: 1.0) }
  }

  /// Time on screen required to log impression with `ScrollTracker`.
  @objc public var scrollTrackerDurationThreshold: TimeInterval = 1.0 {
    didSet { bound(&scrollTrackerDurationThreshold, min: 0.0) }
  }

  /// Frequency at which `ScrollTracker` calculates impressions.
  /// Setting this to lower values will increase the amount of
  /// processing that `ScrollTracker` performs.
  @objc public var scrollTrackerUpdateFrequency: TimeInterval = 0.5 {
    didSet { bound(&scrollTrackerUpdateFrequency, min: 0.1, max: 30.0) }
  }

  @objc(PROXrayLevel)
  public enum XrayLevel: Int, Comparable, ConfigEnum {
    // Don't gather any Xray stats data at all.
    case none = 0
    // Gather overall counts for the session for each batch.
    // ie. batches: 40, batches sent successfully: 39, errors: 1
    case batchSummaries = 1
    // Gather stats and logged messages for each call made
    // to the metrics library.
    case callDetails = 2
    // Gathers stats and logged messages for each call made
    // to the metrics library, as well as stack traces where the
    // calls were made.
    case callDetailsAndStackTraces = 3
  }
  /// Level of Xray profiling for this session.
  /// Setting this to `.none` also forces
  /// `diagnosticsIncludeBatchSummaries` to be false.
  @objc public var xrayLevel: XrayLevel = .none {
    didSet {
      validateEnum(&xrayLevel, defaultValue: .none)
      if xrayLevel == .none && diagnosticsIncludeBatchSummaries {
        diagnosticsIncludeBatchSummaries = false
      }
    }
  }

  @objc(PROOSLogLevel)
  public enum OSLogLevel: Int, Comparable, ConfigEnum {
    /// No logging for anything.
    case none = 0
    /// Logging only for errors.
    case error = 1
    /// Logging for errors and warnings.
    case warning = 2
    /// Logging for info messages (and above).
    case info = 3
    /// Logging for debug messages (and above).
    case debug = 4

    #if DEBUG
    static let `default`: OSLogLevel = .debug
    #else
    static let `default`: OSLogLevel = .none
    #endif
  }
  /// Whether to use OSLog (console logging) to output messages.
  /// OSLog typically incurs minimal overhead and can be useful for
  /// verifying that logging works from the client side.
  /// If `xrayEnabled` is also set, then setting `osLogLevel`
  /// to `info` or higher turns on signposts in Instruments.
  @objc public var osLogLevel: OSLogLevel = .default {
    didSet { validateEnum(&osLogLevel, defaultValue: .default) }
  }

  /// Whether mobile diagnostic messages include batch summaries
  /// from Xray. Setting this to `true` also forces `xrayLevel` to
  /// be at least `.batchSummaries`.
  @objc public var diagnosticsIncludeBatchSummaries: Bool = false {
    didSet {
      if diagnosticsIncludeBatchSummaries && xrayLevel == .none {
        xrayLevel = .batchSummaries
      }
    }
  }

  /// Whether mobile diagnostic messages include a history of
  /// ancestor IDs being set for the session.
  @objc public var diagnosticsIncludeAncestorIDHistory: Bool = false

  /// Whether event messages include the `IdentifierProvenances`
  /// message.
  @objc public var eventsIncludeIDProvenances: Bool = false

  /// Whether event messages include the `ClientPosition` message.
  @objc public var eventsIncludeClientPositions: Bool = false

  /// Percentage of randomly sampled clients that will send all
  /// diagnostics. A value of 0 disables diagnostic sampling for
  /// all clients. For example, setting this value to `5` will
  /// cause a random 5% across all users to be cohorted into
  /// sending diagnostics.
  ///
  /// # End date
  /// If you enable diagnostics sampling, you must also provide
  /// an explicit end date via `diagnosticsSamplingEndDateString`.
  /// On and after this date, sampling is disabled across all
  /// users. **Always use an absolute date for this value.**
  ///
  /// This feature is designed for short-term diagnostics usage
  /// only. Do not leave it running in production without an end
  /// date in mind.
  ///
  /// # Remote Config interoperability
  /// Designed for use on platforms where Remote Config is not
  /// available. If Remote Config is enabled, this sampling
  /// configuration is ignored. Random sampling is designed to
  /// replicate rudimentary experiment cohorting entirely
  /// client-side.
  ///
  /// Likewise, setting diagnostic sampling flags (either this
  /// flag or `diagnosticsSamplingEndDateString`) via Remote
  /// Config does nothing.
  ///
  /// # Cohorting
  /// Attempts to create a consistent cohort for the set of users
  /// with sampling enabled. To this end, sampling is done using
  /// the following:
  /// 1. A hash of the persisted `logUserID`. This should persist
  ///    while the same account is logged in. This also applies to
  ///    signed-out users until they log in.
  /// 2. If 1 is not available, uses
  ///    `UIDevice.current.identifierForVendor`. This should persist
  ///    for (at least) the duration of app install.
  /// 3. If 2 is not available, generates a new random UUID for
  ///    the session. This persists only for the current session.
  /// See `ClientConfigService` for sampling implementation.
  ///
  /// # Diagnostic features
  /// If sampling is enabled, the current logging session proceeds
  /// as though the following flags are enabled:
  /// - `diagnosticsIncludeBatchSummaries`
  /// - `diagnosticsIncludeAncestorIDHistory`
  /// - `eventsIncludeIDProvenances`
  /// - `eventsIncludeClientPositions`
  ///
  /// If you set any of those flags individually to `true` and then
  /// enable diagnostics sampling, the flags you set will always be
  /// enabled, and the other diagnostics flags will be enabled
  /// according to random sampling.
  @objc public var diagnosticsSamplingPercentage: Int = 0 {
    didSet { bound(&diagnosticsSamplingPercentage, min: 0, max: 100) }
  }

  /// Explicit end date for `diagnosticsSamplingPercentage`,
  /// format `yyyy-MM-dd`. For example: `2022-01-01`, `2022-02-28`.
  /// On and after this date, sampling is disabled across all
  /// users. **Always use an absolute date for this value.**
  ///
  /// This property is a `String` and not a `Date` because it's
  /// much easier to specify absolute dates using `String`s than
  /// `Date`s in ObjC/Swift.
  @objc public var diagnosticsSamplingEndDateString: String = ""

  @objc(PROLoggingAnomalyHandling)
  public enum LoggingAnomalyHandling: Int, Comparable, ConfigEnum {
    /// Ignore all logging anomalies. Default in production.
    case none = 0
    /// Logs anomalies to console.
    case consoleLog = 1
    /// Interrupts UI with a modal dialog. Default in development.
    case modalDialog = 2
    /// Triggers a breakpoint when running in debug. This may not be
    /// useful for React Native apps.
    case breakInDebugger = 3

    #if DEBUG
    static let `default`: LoggingAnomalyHandling = .modalDialog
    #else
    static let `default`: LoggingAnomalyHandling = .none
    #endif
  }

  /// How to handle anomalies (errors/warnings) from logging calls.
  @objc public var loggingAnomalyHandling: LoggingAnomalyHandling = .default {
    didSet { validateEnum(&loggingAnomalyHandling, defaultValue: .default) }
  }

  /// Partner marketplace name.
  @objc public var partnerName: String = ""

  /// Contact info at Promoted for engineering questions.
  @objc public var promotedContactInfo: [String] = []

  @objc private var assertInValidation: Bool = true

  @objc public override init() {}

  convenience init(_ other: _ObjCClientConfig) {
    self.init()
    let mirror = Mirror(reflecting: other)
    for child in mirror.children {
      guard let label = child.label else { continue }
      setValue(child.value, forKey: label)
    }
  }
}

// MARK: - Diagnostics
extension _ObjCClientConfig {
  func setAllDiagnosticsEnabled(_ enabled: Bool) {
    diagnosticsIncludeBatchSummaries = enabled
    diagnosticsIncludeAncestorIDHistory = enabled
    eventsIncludeIDProvenances = enabled
    eventsIncludeClientPositions = enabled
  }

  var diagnosticsSamplingEndDate: Date? {
    Date(ymdString: diagnosticsSamplingEndDateString)
  }
}

// MARK: - Value
extension _ObjCClientConfig {
  // There are some rough edges with ObjC interop and
  // Swift enums. These next two methods deal with that.
  public override func value(forKey key: String) -> Any? {
    let value = super.value(forKey: key)
    switch key {
    case "metricsLoggingWireFormat":
      if let intValue = value as? Int {
        return MetricsLoggingWireFormat(rawValue: intValue)
      }
    case "xrayLevel":
      if let intValue = value as? Int {
        return XrayLevel(rawValue: intValue)
      }
    case "osLogLevel":
      if let intValue = value as? Int {
        return OSLogLevel(rawValue: intValue)
      }
    case "loggingAnomalyHandling":
      if let intValue = value as? Int {
        return LoggingAnomalyHandling(rawValue: intValue)
      }
    default:
      break
    }
    return value
  }

  public override func setValue(_ value: Any?, forKey key: String) {
    let convertedValue: Any?
    switch value {
    case let wire as MetricsLoggingWireFormat:
      convertedValue = wire.rawValue
    case let xray as XrayLevel:
      convertedValue = xray.rawValue
    case let osLog as OSLogLevel:
      convertedValue = osLog.rawValue
    case let logging as LoggingAnomalyHandling:
      convertedValue = logging.rawValue
    default:
      convertedValue = value
    }
    super.setValue(convertedValue, forKey: key)
  }
}

// MARK: - Codable
extension _ObjCClientConfig: Codable {}

// MARK: - Validation
extension _ObjCClientConfig {

  private func bound<T: Comparable>(
    _ value: inout T,
    min: T? = nil,
    max: T? = nil,
    propertyName: String = #function
  ) {
    if let min = min {
      assert(
        !assertInValidation || value >= min,
        "\(propertyName): min value \(min) (> \(value))"
      )
      value = Swift.max(min, value)
    }
    if let max = max {
      assert(
        !assertInValidation || value <= max,
        "\(propertyName): max value \(max) (< \(value))"
      )
      value = Swift.min(max, value)
    }
  }

  /// Validate enums and set them to appropriate defaults.
  /// Deserialization might produce invalid enum values.
  private func validateEnum<T: ConfigEnum>(
    _ value: inout T,
    defaultValue: T,
    propertyName: String = #function
  ) {
    if !T.allCases.contains(value) {
      assert(
        !assertInValidation,
        "\(propertyName): unknown case for enum " +
          "\(String(describing: type(of: value))) = " +
          "\(String(describing: value))"
      )
      value = defaultValue
    }
  }

  func validateConfig() throws {
    if URL(string: metricsLoggingURL) == nil {
      throw ClientConfigError.invalidURL(urlString: metricsLoggingURL)
    }
    if metricsLoggingAPIKey.isEmpty {
      throw ClientConfigError.missingAPIKey
    }
    if !devMetricsLoggingURL.isEmpty {
      if URL(string: devMetricsLoggingURL) == nil {
        throw ClientConfigError.invalidURL(urlString: devMetricsLoggingURL)
      }
      if devMetricsLoggingAPIKey.isEmpty {
        throw ClientConfigError.missingDevAPIKey
      }
    }
    if diagnosticsSamplingPercentage > 0 {
      if diagnosticsSamplingEndDate == nil {
        throw ClientConfigError.invalidDiagnosticsSamplingEndDateString(
          diagnosticsSamplingEndDateString
        )
      }
    }
  }
}

// MARK: - Testing
extension _ObjCClientConfig {
  func disableAssertInValidationForTesting() {
    assertInValidation = false
  }
}

// MARK: - ConfigEnums
public extension ConfigEnum {
  init?(_ name: String) {
    for value in Self.allCases {
      if value.description == name {
        self = value
        return
      }
    }
    return nil
  }
}

extension _ObjCClientConfig.MetricsLoggingWireFormat {
  public var description: String {
    switch self {
    case .json:
      return "json"
    case .binary:
      return "binary"
    default:
      return "unknown"
    }
  }
}

extension _ObjCClientConfig.XrayLevel {
  public var description: String {
    switch self {
    case .none:
      return "none"
    case .batchSummaries:
      return "batchSummaries"
    case .callDetails:
      return "callDetails"
    case .callDetailsAndStackTraces:
      return "callDetailsAndStackTraces"
    default:
      return "unknown"
    }
  }
}

extension _ObjCClientConfig.OSLogLevel {
  public var description: String {
    switch self {
    case .none:
      return "none"
    case .error:
      return "error"
    case .warning:
      return "warning"
    case .info:
      return "info"
    case .debug:
      return "debug"
    default:
      return "unknown"
    }
  }
}

extension _ObjCClientConfig.LoggingAnomalyHandling {
  public var description: String {
    switch self {
    case .none:
      return "none"
    case .consoleLog:
      return "consoleLog"
    case .modalDialog:
      return "modalDialog"
    default:
      return "unknown"
    }
  }
}

// MARK: - Comparison and serialization
public func < <T: RawRepresentable>(
  a: T, b: T
) -> Bool where T.RawValue: Comparable {
  return a.rawValue < b.rawValue
}

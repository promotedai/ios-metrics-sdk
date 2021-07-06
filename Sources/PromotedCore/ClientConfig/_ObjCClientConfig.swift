import Foundation

/// Enumeration value in config.
public typealias ConfigEnum = (
  CaseIterable &
  Codable &
  CustomStringConvertible &
  Equatable &
  RawRepresentable
)

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
 5. Make it conform to `ConfigEnum`.
 6. Add an extension that contains `var description`.

 The final three items ensure that it works with remote config
 and serialization.

 Example:
 ```swift
 @objc(PROAlohaEnum)
 public enum AlohaEnum: Int, ConfigEnum {
   case hello = 1
   case goodbye = 2
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
    /// https://developers.google.com/protocol-buffers/docs/proto3#json
    case json = 1
    /// https://developers.google.com/protocol-buffers/docs/encoding
    case binary = 2
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
    case none = 1
    // Gather overall counts for the session for each batch.
    // ie. batches: 40, batches sent successfully: 39, errors: 1
    case batchSummaries = 2
    // Gather stats and logged messages for each call made
    // to the metrics library.
    case callDetails = 3
    // Gathers stats and logged messages for each call made
    // to the metrics library, as well as stack traces where the
    // calls were made.
    case callDetailsAndStackTraces = 4
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
    case none = 1
    /// Logging only for errors.
    case error = 2
    /// Logging for errors and warnings.
    case warning = 3
    /// Logging for info messages (and above).
    case info = 4
    /// Logging for debug messages (and above).
    case debug = 5
  }
  /// Whether to use OSLog (console logging) to output messages.
  /// OSLog typically incurs minimal overhead and can be useful for
  /// verifying that logging works from the client side.
  /// If `xrayEnabled` is also set, then setting `osLogLevel`
  /// to `info` or higher turns on signposts in Instruments.
  @objc public var osLogLevel: OSLogLevel = .none {
    didSet { validateEnum(&osLogLevel, defaultValue: .none) }
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

  var anyDiagnosticsEnabled: Bool {
    diagnosticsIncludeBatchSummaries ||
      diagnosticsIncludeAncestorIDHistory
  }

  @objc private var assertInValidation: Bool = true

  /// Whether mobile diagnostic messages include a history of
  /// ancestor IDs being set for the session.
  @objc public var diagnosticsIncludeAncestorIDHistory: Bool = false

  @objc public override init() {}

  convenience init(_ other: _ObjCClientConfig) {
    self.init()
    let mirror = Mirror(reflecting: other)
    for child in mirror.children {
      guard let label = child.label else { continue }
      setValue(child.value, forKey: label)
    }
  }

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

// MARK: - Comparison and serialization
public func < <T: RawRepresentable>(
  a: T, b: T
) -> Bool where T.RawValue: Comparable {
  return a.rawValue < b.rawValue
}

import Foundation

/// Use `ClientConfig.ConfigEnum` instead.
public protocol _ConfigEnum:
  CaseIterable, Codable, CustomStringConvertible, Equatable {}

// MARK: - ClientConfig properties
/**
 Configuration for Promoted logging library internal behavior.
 See `ClientConfigService` for information about how these
 configs are loaded.

 This struct should only contain properties that apply to the
 Promoted logging library in general. Mechanisms that alter
 the way that client code calls the Promoted logging library
 should go in client code, external from this config.

 # Objective C interoperability

 The Objective C interoperability of this struct is contained
 in a class called `_ObjCClientConfig`. Use that class only in
 Objective C (where it's named `PROClientConfig`).

 We chose to make this separate class for the following reasons.

 1. `ClientConfig` makes most sense as a struct in Swift, since
    its semantics are always pass-by-value:
    a. Attempting to maintain this as a class in Swift can lead
       to hard-to-catch issues when forgetting to copy.
    b. We need to make `ClientConfig` immutable after logging
       services are started. Structs can be made read-only
       easily because they are pass-by-value.
 2. Objective C can't work with Swift structs, only classes.
 3. The extra code needed to maintain this bridge can be tested,
    but it's much harder to test for mis-uses of `ClientConfig`
    as a class.

 # Adding new properties.

 When adding a new property, do the following:

 1. Ensure the type is `Codable` and can be expressed in
    Objective C. If you're adding a new enum type as well,
    see the next section.
 2. Add a property of same name and type in
    `_ObjCClientConfig`.
 3. Add the property to the `allKeyPaths` map.
 4. If you added a new type that isn't covered by the switch
    statements in `value(forName name: String)` and
    `setValue(_ value: Any, forName name: String)`, add the
    type in both switch statements.

 # Adding new enums

 When adding a new enum property, do the following:

 1. Make the type and value public.
 2. Make the type `@objc` and give it a name prefixed with `PRO`.
    The type will be referenced from `_ObjCClientConfig`.
 3. Make it an `Int` enum.
 4. Make it conform to `ConfigEnum`.
 5. Add an extension that contains `var description`.

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
public struct ClientConfig: Codable {
  /// Enumeration value in config.
  public typealias ConfigEnum = _ConfigEnum

  /// Controls whether log messages are sent over the network.
  /// Setting this property to `false` will prevent log messages
  /// from being sent, but these messages may still be collected
  /// at runtime and stored in memory.
  public var loggingEnabled: Bool = true

  /// URL for logging endpoint as used by `NetworkConnection`.
  /// Implementations of `NetworkConnection` from Promoted will
  /// use this field. Custom implementations of `NetworkConnection`
  /// may vary in behavior.
  public var metricsLoggingURL: String = ""

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
  public var devMetricsLoggingURL: String = ""
  
  /// API key for logging endpoint.
  /// Implementations of `NetworkConnection` from Promoted will
  /// use this field. Custom implementations of `NetworkConnection`
  /// may vary in behavior.
  public var metricsLoggingAPIKey: String = ""
  
  /// API key for logging endpoint for debug/staging purposes.
  /// Used when the app is running in debug configuration.
  ///
  /// If this property is not set, then debug builds will use
  /// `metricsLoggingAPIKey` for logging endpoint API key.
  ///
  /// Implementations of `NetworkConnection` from Promoted will
  /// use this field. Custom implementations of `NetworkConnection`
  /// may vary in behavior.
  public var devMetricsLoggingAPIKey: String = ""

  /// HTTP header field for API key.
  public var apiKeyHTTPHeaderField: String = "x-api-key"

  /// Format to use when sending protobuf log messages over network.
  @objc(PROMetricsLoggingWireFormat)
  public enum MetricsLoggingWireFormat: Int, ConfigEnum {
    /// https://developers.google.com/protocol-buffers/docs/proto3#json
    case json = 1
    /// https://developers.google.com/protocol-buffers/docs/encoding
    case binary = 2
  }
  /// Format to use when sending protobuf log messages over network.
  public var metricsLoggingWireFormat: MetricsLoggingWireFormat = .binary {
    didSet { validateEnum(&metricsLoggingWireFormat, defaultValue: .binary) }
  }

  /// Interval at which log messages are sent over the network.
  /// Setting this to lower values will increase the frequency
  /// at which log messages are sent.
  public var loggingFlushInterval: TimeInterval = 10.0 {
    didSet { bound(&loggingFlushInterval, min: 1.0, max: 300.0) }
  }

  /// Whether to automatically flush all pending log messages
  /// when the application resigns active.
  public var flushLoggingOnResignActive: Bool = true

  /// Ratio of the view that must be visible to log impression
  /// with `ScrollTracker`.
  public var scrollTrackerVisibilityThreshold: Float = 0.5 {
    didSet { bound(&scrollTrackerVisibilityThreshold, min: 0.0, max: 1.0) }
  }

  /// Time on screen required to log impression with `ScrollTracker`.
  public var scrollTrackerDurationThreshold: TimeInterval = 1.0 {
    didSet { bound(&scrollTrackerDurationThreshold, min: 0.0) }
  }

  /// Frequency at which `ScrollTracker` calculates impressions.
  /// Setting this to lower values will increase the amount of
  /// processing that `ScrollTracker` performs.
  public var scrollTrackerUpdateFrequency: TimeInterval = 0.5 {
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
  public var xrayLevel: XrayLevel = .none {
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
  public var osLogLevel: OSLogLevel = .none {
    didSet { validateEnum(&osLogLevel, defaultValue: .none) }
  }

  /// Whether mobile diagnostic messages include batch summaries
  /// from Xray. Setting this to `true` also forces `xrayLevel` to
  /// be at least `.batchSummaries`.
  public var diagnosticsIncludeBatchSummaries: Bool = false {
    didSet {
      if diagnosticsIncludeBatchSummaries && xrayLevel == .none {
        xrayLevel = .batchSummaries
      }
    }
  }

  /// Whether mobile diagnostic messages include a history of
  /// ancestor IDs being set for the session.
  public var diagnosticsIncludeAncestorIDHistory: Bool = false

  var anyDiagnosticsEnabled: Bool {
    diagnosticsIncludeBatchSummaries ||
      diagnosticsIncludeAncestorIDHistory
  }

  private var assertInValidation: Bool = true
}

// MARK: - Key paths

public extension ClientConfig {

  typealias AnyConfigKeyPath = PartialKeyPath<ClientConfig>

  static let allKeyPaths: [String: AnyConfigKeyPath] = [
    "apiKeyHTTPHeaderField": \ClientConfig.apiKeyHTTPHeaderField,
    "devMetricsLoggingAPIKey": \ClientConfig.devMetricsLoggingAPIKey,
    "devMetricsLoggingURL": \ClientConfig.devMetricsLoggingURL,
    "diagnosticsIncludeAncestorIDHistory":
      \ClientConfig.diagnosticsIncludeAncestorIDHistory,
    "diagnosticsIncludeBatchSummaries":
      \ClientConfig.diagnosticsIncludeBatchSummaries,
    "flushLoggingOnResignActive": \ClientConfig.flushLoggingOnResignActive,
    "loggingEnabled": \ClientConfig.loggingEnabled,
    "loggingFlushInterval": \ClientConfig.loggingFlushInterval,
    "metricsLoggingAPIKey": \ClientConfig.metricsLoggingAPIKey,
    "metricsLoggingWireFormat": \ClientConfig.metricsLoggingWireFormat,
    "metricsLoggingURL": \ClientConfig.metricsLoggingURL,
    "osLogLevel": \ClientConfig.osLogLevel,
    "scrollTrackerDurationThreshold":
      \ClientConfig.scrollTrackerDurationThreshold,
    "scrollTrackerUpdateFrequency": \ClientConfig.scrollTrackerUpdateFrequency,
    "scrollTrackerVisibilityThreshold":
      \ClientConfig.scrollTrackerVisibilityThreshold,
    "xrayLevel": \ClientConfig.xrayLevel,
  ]

  typealias ConfigKeyPath<Value> = KeyPath<ClientConfig, Value>

  /// Returns value for named property.
  func value(forName name: String) -> Any? {
    guard let keyPath = Self.allKeyPaths[name] else {
      assert(!assertInValidation, "Unknown key: \(name)")
      return nil
    }
    switch keyPath {
    case let k as ConfigKeyPath<Bool>:
      return self[keyPath: k]
    case let k as ConfigKeyPath<String>:
      return self[keyPath: k]
    case let k as ConfigKeyPath<TimeInterval>:
      return self[keyPath: k]
    case let k as ConfigKeyPath<Float>:
      return self[keyPath: k]
    case let k as ConfigKeyPath<MetricsLoggingWireFormat>:
      return self[keyPath: k]
    case let k as ConfigKeyPath<XrayLevel>:
      return self[keyPath: k]
    case let k as ConfigKeyPath<OSLogLevel>:
      return self[keyPath: k]
    default:
      break
    }
    assert(!assertInValidation, "Unknown key: \(name)")
    return nil
  }

  typealias WritableConfigKeyPath<Value> = WritableKeyPath<ClientConfig, Value>

  /// Sets value for named property.
  mutating func setValue(_ value: Any, forName name: String) {
    guard let keyPath = Self.allKeyPaths[name] else {
      assert(!assertInValidation, "Unknown key: \(name)")
      return
    }
    switch value {
    case let intValue as Bool:
      if let k = keyPath as? WritableConfigKeyPath<Bool> {
        self[keyPath: k] = intValue
        return
      }
    case let stringValue as String:
      if let k = keyPath as? WritableConfigKeyPath<String> {
        self[keyPath: k] = stringValue
        return
      }
    case let timeValue as TimeInterval:
      if let k = keyPath as? WritableConfigKeyPath<TimeInterval> {
        self[keyPath: k] = timeValue
        return
      }
    case let floatValue as Float:
      if let k = keyPath as? WritableConfigKeyPath<Float> {
        self[keyPath: k] = floatValue
        return
      }
    case let m as MetricsLoggingWireFormat:
      if let k = keyPath as? WritableConfigKeyPath<MetricsLoggingWireFormat> {
        self[keyPath: k] = m
        return
      }
    case let x as XrayLevel:
      if let k = keyPath as? WritableConfigKeyPath<XrayLevel> {
        self[keyPath: k] = x
        return
      }
    case let o as OSLogLevel:
      if let k = keyPath as? WritableConfigKeyPath<OSLogLevel> {
        self[keyPath: k] = o
        return
      }
    default:
      break
    }
    assert(
      !assertInValidation,
      "Could not set value \(String(describing: value)) for key \(name)"
    )
  }
}

// MARK: - ObjC compatibility
public extension ClientConfig {

  init(_ config: _ObjCClientConfig) {
    let mirror = Mirror(reflecting: config)
    for child in mirror.children {
      guard let name = child.label else { continue }
      setValue(child.value, forName: name)
    }
  }
}

// MARK: - Validation
extension ClientConfig {

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
extension ClientConfig {
  mutating func disableAssertInValidationForTesting() {
    assertInValidation = false
  }
}

// MARK: - Protocol composition
protocol InitialConfigSource {
  var initialConfig: ClientConfig { get }
}

protocol ClientConfigSource: InitialConfigSource {
  var clientConfig: ClientConfig { get }
}

// MARK: - Comparison and serialization
public func < <T: RawRepresentable>(
  a: T, b: T
) -> Bool where T.RawValue: Comparable {
  return a.rawValue < b.rawValue
}

public extension _ConfigEnum {
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

extension ClientConfig.MetricsLoggingWireFormat {
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

extension ClientConfig.XrayLevel {
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

extension ClientConfig.OSLogLevel {
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

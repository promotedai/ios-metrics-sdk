import Foundation

// MARK: - ClientConfig properties
/**
 Configuration for Promoted logging library internal behavior.
 See `ClientConfigService` for information about how these
 configs are loaded.

 This class should only contain properties that apply to the
 Promoted logging library in general. Mechanisms that alter
 the way that client code calls the Promoted logging library
 should go in client code, external from this config.

 Do not change the properties of this object once loaded from
 `ClientConfigService`.

 # Validation

 When adding new properties that are numerical or enum values,
 make sure to validate in `didSet` to ensure that incorrect
 values don't cause unreasonable behavior during runtime. See
 `bound` and `validateEnum`.
 */
@objc(PROClientConfig)
public final class ClientConfig: NSObject, Codable {
  public typealias ConfigEnum = CaseIterable & Codable & ExpressibleByStringLiteral

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
  @objc public var metricsLoggingWireFormat: MetricsLoggingWireFormat = .binary {
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

  /// Whether mobile diagnostic messages include a history of
  /// ancestor IDs being set for the session.
  @objc public var diagnosticsIncludeAncestorIDHistory: Bool = false

  var anyDiagnosticsEnabled: Bool {
    diagnosticsIncludeBatchSummaries ||
      diagnosticsIncludeAncestorIDHistory
  }

  private var assertInValidation: Bool = true

  @objc public override init() {}

  public init(_ config: ClientConfig) {
    // ClientConfig really should be a struct, but isn't because
    // of Objective C compatibility.
    self.loggingEnabled = config.loggingEnabled
    self.metricsLoggingURL = config.metricsLoggingURL
    self.metricsLoggingAPIKey = config.metricsLoggingAPIKey
    self.devMetricsLoggingURL = config.devMetricsLoggingURL
    self.devMetricsLoggingAPIKey = config.devMetricsLoggingAPIKey
    self.metricsLoggingWireFormat = config.metricsLoggingWireFormat
    self.loggingFlushInterval = config.loggingFlushInterval
    self.scrollTrackerVisibilityThreshold = config.scrollTrackerVisibilityThreshold
    self.scrollTrackerDurationThreshold = config.scrollTrackerDurationThreshold
    self.scrollTrackerUpdateFrequency = config.scrollTrackerUpdateFrequency
    self.xrayLevel = config.xrayLevel
    self.osLogLevel = config.osLogLevel
    self.diagnosticsIncludeBatchSummaries = config.diagnosticsIncludeBatchSummaries
    self.diagnosticsIncludeAncestorIDHistory = config.diagnosticsIncludeAncestorIDHistory
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
      assert(!assertInValidation || value >= min,
             "\(propertyName): min value \(min) (> \(value))")
      value = Swift.max(min, value)
    }
    if let max = max {
      assert(!assertInValidation || value <= max,
             "\(propertyName): max value \(max) (< \(value))")
      value = Swift.min(max, value)
    }
  }

  /// Validate enums and set them to appropriate defaults.
  /// Deserialization might produce invalid enum values.
  private func validateEnum<T: CaseIterable & Equatable>(
    _ value: inout T,
    defaultValue: T,
    propertyName: String = #function
  ) {
    if !T.allCases.contains(value) {
      // Not printing `value` because `String(describing: value)`
      // just gives the enum class name.
      // TODO: Figure out how to print the invalid value.
      assert(!assertInValidation,
             "\(propertyName): unknown case for enum " +
              "\(String(describing: type(of: value)))")
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
  func disableAssertInValidationForTesting() { assertInValidation = false }
}

// MARK: - Protocol composition
protocol InitialConfigSource: NoDeps {
  var initialConfig: ClientConfig { get }
}

protocol ClientConfigSource: InitialConfigSource {
  var clientConfig: ClientConfig { get }
}

// MARK: - Comparison and serialization
public func < <T: RawRepresentable>(a: T, b: T) -> Bool
  where T.RawValue: Comparable {
  return a.rawValue < b.rawValue
}

public extension ClientConfig.MetricsLoggingWireFormat {
  init(stringLiteral: String) {
    switch stringLiteral {
    case "json":
      self = .json
    case "binary":
      self = .binary
    default:
      self = .binary
    }
  }
}

public extension ClientConfig.XrayLevel {
  init(stringLiteral: String) {
    switch stringLiteral {
    case "none":
      self = .none
    case "batchSummaries":
      self = .batchSummaries
    case "callDetails":
      self = .callDetails
    case "callDetailsAndStackTraces":
      self = .callDetailsAndStackTraces
    default:
      self = .none
    }
  }
}

public extension ClientConfig.OSLogLevel {
  init(stringLiteral: String) {
    switch stringLiteral {
    case "none":
      self = .none
    case "error":
      self = .error
    case "warning":
      self = .warning
    case "info":
      self = .info
    case "debug":
      self = .debug
    default:
      self = .none
    }
  }
}

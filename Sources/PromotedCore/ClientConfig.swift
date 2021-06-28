import Foundation

/**
 Configuration for Promoted logging library internal behavior.
 
 Properties on the instance of `ClientConfig` obtained from
 `ClientConfigService` can change when the service loads from
 asynchronous sources. Users of this class may cache instances
 of the `ClientConfig` from the active `ClientConfigService`
 and repeatedly read values from the `ClientConfig`, and the
 values read will always be up to date.
 
 Users should also be careful to read and cache values from
 this class in a way that takes into account the dynamic nature
 of these properties. Use KVO to listen for changes to any
 single property, or `ClientConfigListener` to listen for
 changes to the entire `ClientConfig`.

 This class should only contain properties that apply to the
 Promoted logging library in general. Mechanisms that alter
 the way that client code calls the Promoted logging library
 should go in client code, external from this config.
 */
@objc(PROClientConfig)
public final class ClientConfig: NSObject {

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
  public enum MetricsLoggingWireFormat: Int {
    /// https://developers.google.com/protocol-buffers/docs/proto3#json
    case json = 1
    /// https://developers.google.com/protocol-buffers/docs/encoding
    case binary = 2
  }
  /// Format to use when sending protobuf log messages over network.
  @objc public var metricsLoggingWireFormat: MetricsLoggingWireFormat = .binary
  
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
  public enum XrayLevel: Int, Comparable {
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
      if xrayLevel == .none && diagnosticsIncludeBatchSummaries {
        diagnosticsIncludeBatchSummaries = false
      }
    }
  }

  @objc(PROOSLogLevel)
  public enum OSLogLevel: Int, Comparable {
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
  @objc public var osLogLevel: OSLogLevel = .none

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

  func bound<T: Comparable>(_ value: inout T, min: T? = nil, max: T? = nil,
                            function: String = #function) {
    if let min = min {
      assert(value >= min, "\(function): min value \(min) (> \(value))")
      value = Swift.max(min, value)
    }
    if let max = max {
      assert(value <= max, "\(function): max value \(max) (< \(value))")
      value = Swift.min(max, value)
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

protocol ClientConfigSource {
  var clientConfig: ClientConfig { get }
  var initialConfig: ClientConfig { get }
}

public func < <T: RawRepresentable>(a: T, b: T) -> Bool
  where T.RawValue: Comparable {
  return a.rawValue < b.rawValue
}

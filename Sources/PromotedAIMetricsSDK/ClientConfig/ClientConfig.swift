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
  @objc public var devMetricsLoggingAPIKey: String = ""

  /// Format to use when sending protobuf log messages over network.
  public enum MetricsLoggingWireFormat: Int {
    /// https://developers.google.com/protocol-buffers/docs/proto3#json
    case json = 1
    /// https://developers.google.com/protocol-buffers/docs/encoding
    case binary = 2
  }
  /// Format to use when sending protobuf log messages over network.
  public var metricsLoggingWireFormat: MetricsLoggingWireFormat = .binary
  
  /// Interval at which log messages are sent over the network.
  /// Setting this to lower values will increase the frequency
  /// at which log messages are sent.
  public var loggingFlushInterval: TimeInterval = 10.0
  
  /// Ratio of the view that must be visible to log impression
  /// with `ScrollTracker`.
  public var scrollTrackerVisibilityThreshold: Float = 0.5

  /// Time on screen required to log impression with `ScrollTracker`.
  public var scrollTrackerDurationThreshold: TimeInterval = 1.0

  /// Frequency at which `ScrollTracker` calculates impressions.
  /// Setting this to lower values will increase the amount of
  /// processing that `ScrollTracker` performs.
  public var scrollTrackerUpdateFrequency: TimeInterval = 0.5
  
  /// Whether to enable Xray profiling for this session.
  @objc public var xrayEnabled: Bool = false

  /// Whether to include call stacks on Xray profiles.
  /// Call stacks are expensive to compute.
  @objc public var xrayExpensiveThreadCallStacksEnabled: Bool = false

  /// Whether to use OSLog to output messages.
  /// OSLog typically incurs minimal overhead and can be useful for
  /// verifying that logging works from the client side.
  /// If `xrayEnabled` is also set, then setting `osLogEnabled`
  /// turns on signposts in Instruments.
  @objc public var osLogEnabled: Bool = false

  @objc public override init() {}
}

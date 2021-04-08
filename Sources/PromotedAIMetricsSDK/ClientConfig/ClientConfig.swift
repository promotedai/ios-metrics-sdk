import Foundation

/**
 Configuration for Promoted logging library internal behavior.
 
 Properties on this object can change when `ClientConfigService`
 loads from asynchronous sources. For this reason, users
 should only cache instances of the `ClientConfig` from the
 active `ClientConfigService`, and not any other instances.
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
public class ClientConfig: NSObject {

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

  public enum MetricsLoggingWireFormat: Int {
    case json = 1
    case binary = 2
  }
  /// Format to use when sending protobuf log messages over network.
  ///
  /// - https://developers.google.com/protocol-buffers/docs/encoding
  /// - https://developers.google.com/protocol-buffers/docs/proto3#json
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
  
  @objc public override init() {}
  
  func copyFrom(_ other: ClientConfig) {
    let mirror = Mirror(reflecting: other)
    for (label, value) in mirror.children {
      if let label = label {
        self.setValue(value, forKey: label)
      }
    }
  }
}

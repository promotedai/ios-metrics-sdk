import Foundation

@objc(PROMetricsLoggingWireFormat)
public enum MetricsLoggingWireFormat: Int {
  case json = 1
  case binary = 2
}

@objc(PROClientConfig)
public protocol ClientConfig {

  var loggingEnabled: Bool { get }
  
  @objc var metricsLoggingURL: String { get }
  @objc var devMetricsLoggingURL: String { get }
  
  @objc var metricsLoggingAPIKey: String { get }
  @objc var devMetricsLoggingAPIKey: String { get }
  
  var metricsLoggingWireFormat: MetricsLoggingWireFormat { get }
  
  var loggingFlushInterval: TimeInterval { get }
  
  var scrollTrackerVisibilityThreshold: Float { get }
  var scrollTrackerDurationThreshold: TimeInterval { get }
  var scrollTrackerUpdateFrequency: TimeInterval { get }
}

@objc(PROLocalClientConfig)
public class LocalClientConfig: NSObject, ClientConfig {

  public var loggingEnabled: Bool = true
  
  @objc public var metricsLoggingURL: String = ""
  @objc public var devMetricsLoggingURL: String = ""
  
  @objc public var metricsLoggingAPIKey: String = ""
  @objc public var devMetricsLoggingAPIKey: String = ""
  
  public var metricsLoggingWireFormat: MetricsLoggingWireFormat = .binary
  
  public var loggingFlushInterval: TimeInterval = 10.0
  
  public var scrollTrackerVisibilityThreshold: Float = 0.5
  public var scrollTrackerDurationThreshold: TimeInterval = 1.0
  public var scrollTrackerUpdateFrequency: TimeInterval = 0.5
  
  @objc public override init() {}
}

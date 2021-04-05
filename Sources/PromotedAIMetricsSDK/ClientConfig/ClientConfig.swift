import Foundation

@objc(PROClientConfig)
public class ClientConfig: NSObject {
  
  enum MetricsLoggingWireFormat {
    case json
    case binary
  }
  
  var loggingEnabled: Bool = true
  
  @objc public var metricsLoggingURL: String = ""
  
  @objc public var metricsLoggingAPIKey: String = ""
  
  var metricsLoggingWireFormat: MetricsLoggingWireFormat = .binary
  
  var loggingFlushInterval: TimeInterval = 10.0
  
  var scrollTrackerVisibilityThreshold: Float = 0.5
  var scrollTrackerDurationThreshold: TimeInterval = 1.0
  var scrollTrackerUpdateFrequency: TimeInterval = 0.5
  
  @objc public override init() {}
}

import Foundation

/** Configuration of Promoted logging client. */
@objc(PROClientConfig)
public class ClientConfig: NSObject {
  
  enum MetricsLoggingWireFormat {
    case json
    case binary
  }
  
  var loggingEnabled: Bool = true
  
  @objc public var metricsLoggingURL: String = ""
  @objc public var devMetricsLoggingURL: String = ""
  
  @objc public var metricsLoggingAPIKey: String = ""
  @objc public var devMetricsLoggingAPIKey: String = ""
  
  var metricsLoggingWireFormat: MetricsLoggingWireFormat = .binary
  
  var loggingFlushInterval: TimeInterval = 10.0
  
  @objc public override init() {}
}

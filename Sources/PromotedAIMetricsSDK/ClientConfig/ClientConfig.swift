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
  
  @objc var metricsLoggingAPIKey: String { get }
  
  var metricsLoggingWireFormat: MetricsLoggingWireFormat { get }
  
  var loggingFlushInterval: TimeInterval { get }
}

@objc(PROLocalClientConfig)
public class LocalClientConfig: NSObject, ClientConfig {

  public var loggingEnabled: Bool = true
  
  @objc public var metricsLoggingURL: String = ""
  
  @objc public var metricsLoggingAPIKey: String = ""
  
  public var metricsLoggingWireFormat: MetricsLoggingWireFormat = .binary
  
  public var loggingFlushInterval: TimeInterval = 10.0
  
  @objc public override init() {}
}

import Foundation

public struct ClientConfig {
  
  enum MetricsLoggingWireFormat {
    case json
    case binary
  }
  
  var loggingEnabled: Bool = true
  
  public var metricsLoggingURL: String = ""
  
  public var metricsLoggingAPIKey: String = ""
  
  var metricsLoggingWireFormat: MetricsLoggingWireFormat = .binary
  
  var loggingFlushInterval: TimeInterval = 10.0
  
  public init() {}
}

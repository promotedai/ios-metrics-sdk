import Foundation

public struct ClientConfig {
  
  enum MetricsLoggingWireFormat {
    case json
    case binary
  }
  
  static let localMetricsLoggingURLString = "http://rhubarb.local:8080/metrics"
  
  static let devMetricsLoggingURLString =
      "https://5tbepnh11h.execute-api.us-east-2.amazonaws.com/dev/main"
  static let devMetricsLoggingAPIKeyString = "OLpsrVSd565IQmOAR62dO9GkXUJngNo5ZUdCMV70"
  
  var loggingEnabled: Bool = true
  
  var metricsLoggingURL: String = ClientConfig.devMetricsLoggingURLString
  
  var metricsLoggingAPIKey: String? = ClientConfig.devMetricsLoggingAPIKeyString
  
  var metricsLoggingWireFormat: MetricsLoggingWireFormat = .binary
  
  var batchLoggingFlushInterval: TimeInterval = 10.0
}

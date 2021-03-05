import Foundation

public struct ClientConfig {
  
  enum MetricsLoggingWireFormat {
    case json
    case binary
  }
  
  static let localMetricsLoggingURLString = "http://rhubarb.local:8080/metrics"
  
  static let devMetricsLoggingURLString =
      "https://srh9gl3spk.execute-api.us-east-1.amazonaws.com/dev/main"
  static let devMetricsLoggingAPIKeyString = "J8nvCqSFQw8n8JDwK8m1Z3KZY8CpjeT727JVEhuK"
  
  var loggingEnabled: Bool = true
  
  var metricsLoggingURL: String = ClientConfig.devMetricsLoggingURLString
  
  var metricsLoggingAPIKey: String? = ClientConfig.devMetricsLoggingAPIKeyString
  
  var metricsLoggingWireFormat: MetricsLoggingWireFormat = .binary
  
  var batchLoggingFlushInterval: TimeInterval = 10.0
}

import Foundation

open class ClientConfig: NSObject {
  
  public enum MetricsLoggingWireFormat {
    case json
    case base64EncodedBinary
    case binary
  }
  
  static let localMetricsLoggingURLString = "http://rhubarb.local:8080/metrics"
  
  static let devMetricsLoggingURLString =
      "https://srh9gl3spk.execute-api.us-east-1.amazonaws.com/dev/main"
  static let devMetricsLoggingAPIKeyString = "J8nvCqSFQw8n8JDwK8m1Z3KZY8CpjeT727JVEhuK"
  
  public var loggingEnabled: Bool {
    return true
  }
  
  public var metricsLoggingURL: String {
    return ClientConfig.devMetricsLoggingURLString
  }
  
  public var metricsLoggingAPIKey: String? {
    return ClientConfig.devMetricsLoggingAPIKeyString
  }
  
  public var metricsLoggingWireFormat: MetricsLoggingWireFormat {
    return .base64EncodedBinary
  }
  
  public var batchLoggingFlushInterval: TimeInterval {
    return 10.0
  }
}

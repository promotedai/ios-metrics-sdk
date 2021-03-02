import Foundation

open class ClientConfig: NSObject {
  
  private static let localMetricsLoggingURLString = "http://localhost:8080/metrics"
  
  public var loggingEnabled: Bool {
    return true
  }
  
  public var metricsLoggingURL: String {
    return ClientConfig.localMetricsLoggingURLString
  }
  
  public var batchLoggingFlushInterval: TimeInterval {
    return 10.0
  }
}

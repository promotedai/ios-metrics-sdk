import FirebaseRemoteConfig
import Foundation
import PromotedAIMetricsSDK

@objc(PRORemoteClientConfig)
public class RemoteClientConfig: NSObject, ClientConfig {
  
  public var loggingEnabled: Bool {
    return firebaseConfig["loggingEnabled"].boolValue
  }
  
  @objc public var metricsLoggingURL: String {
    return firebaseConfig["metricsLoggingURL"].stringValue ?? ""
  }
  
  @objc public var metricsLoggingAPIKey: String {
    return firebaseConfig["metricsLoggingAPIKey"].stringValue ?? ""
  }
  
  public var metricsLoggingWireFormat: MetricsLoggingWireFormat {
    let n = firebaseConfig["metricsLoggingWireFormat"].numberValue
    return MetricsLoggingWireFormat(rawValue: n.intValue) ?? .binary
  }
  
  public var loggingFlushInterval: TimeInterval {
    return firebaseConfig["loggingFlushInterval"].numberValue.doubleValue
  }

  private let firebaseConfig: RemoteConfig
  
  init(firebaseConfig: RemoteConfig) {
    self.firebaseConfig = firebaseConfig
  }
}

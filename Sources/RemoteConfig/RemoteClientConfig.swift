import FirebaseRemoteConfig
import Foundation
import PromotedAIMetricsSDK

@objc(PRORemoteClientConfig)
public class RemoteClientConfig: NSObject, ClientConfig {
  
  public var loggingEnabled: Bool {
    return firebaseConfig[#function].boolValue
  }
  
  @objc public var metricsLoggingURL: String {
    return firebaseConfig[#function].stringValue ?? ""
  }
  
  @objc public var metricsLoggingAPIKey: String {
    return firebaseConfig[#function].stringValue ?? ""
  }
  
  public var metricsLoggingWireFormat: MetricsLoggingWireFormat {
    let n = firebaseConfig[#function].numberValue
    return MetricsLoggingWireFormat(rawValue: n.intValue) ?? .binary
  }
  
  public var loggingFlushInterval: TimeInterval {
    return firebaseConfig[#function].numberValue.doubleValue
  }

  private let firebaseConfig: RemoteConfig
  
  init(firebaseConfig: RemoteConfig) {
    self.firebaseConfig = firebaseConfig
  }
}

import FirebaseCore
import Foundation
import PromotedAIMetricsSDK

public class ConfigDictionary {
  
  enum PromotedKeys: String {
    case loggingEnabled
    case metricsLoggingURL
    case metricsLoggingAPIKey
    case metricsLoggingWireFormat
    case loggingFlushInterval
  }
  
  enum FirebaseKeys: String {
    case apiKey
    case bundleID
    case clientID
    case trackingID
    case gcmSenderID
    case projectID
    case googleAppID
  }
  
  public class Writer {
    private let firebaseOptions: FirebaseOptions
    private let clientConfig: ClientConfig
    
    public init(firebaseOptions: FirebaseOptions,
                clientConfig: ClientConfig) {
      self.firebaseOptions = firebaseOptions
      self.clientConfig = clientConfig
    }
  }
}

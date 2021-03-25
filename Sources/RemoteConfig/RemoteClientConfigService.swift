import Firebase
import Foundation
import PromotedAIMetricsSDK

class RemoteClientConfigService: AbstractClientConfigService {
  
  override func fetchClientConfig() {
    FirebaseApp.configure()
    let firebaseConfig = RemoteConfig.remoteConfig()
    let settings = RemoteConfigSettings()
    settings.minimumFetchInterval = 0
    firebaseConfig.configSettings = settings
    configureFirebaseDefaults(firebaseConfig)
    firebaseConfig.fetchAndActivate { [weak self] (status, error) in
      switch status {
      case .successFetchedFromRemote, .successUsingPreFetchedData:
        let config = RemoteClientConfig(firebaseConfig: firebaseConfig)
        self?.setClientConfigAndNotifyListeners(config)
      default:
        print("Error: \(error?.localizedDescription ?? "No error available.")")
      }
    }
  }
  
  private func configureFirebaseDefaults(_ firebaseConfig: RemoteConfig) {
    firebaseConfig.setDefaults([
      "loggingEnabled": NSNumber.init(booleanLiteral: initialConfig.loggingEnabled),
      "metricsLoggingURL": initialConfig.metricsLoggingURL as NSObject,
      "metricsLoggingAPIKey": initialConfig.metricsLoggingAPIKey as NSObject,
      "metricsLoggingWireFormat":
          NSNumber.init(value: initialConfig.metricsLoggingWireFormat.rawValue),
      "loggingFlushInterval": NSNumber.init(value: initialConfig.loggingFlushInterval)
    ]);
  }
}

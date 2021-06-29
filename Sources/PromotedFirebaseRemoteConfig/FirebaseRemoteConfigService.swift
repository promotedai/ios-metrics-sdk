import FirebaseRemoteConfig
import Foundation

#if !COCOAPODS
import PromotedCore
#endif

final class FirebaseRemoteConfigService: AbstractClientConfigService {

  override func fetchClientConfig(initialConfig: ClientConfig,
                                  callback: @escaping Callback) throws {
    let remoteConfig = RemoteConfig.remoteConfig()
    #if DEBUG
      let settings = RemoteConfigSettings()
      settings.minimumFetchInterval = 0
      remoteConfig.configSettings = settings
    #endif
    remoteConfig.fetch { status, error in
      if let error = error {
        callback(nil, error)
        return
      }
      switch status {
      case .success:
        var warnings: [String]? = []
        var infos: [String]? = []
        let config = ClientConfig(remoteConfig: remoteConfig, warnings: &warnings, infos: &infos)
        callback(config, nil)
      case .failure, .noFetchYet:
        break
      case .throttled:
        break
      @unknown default:
        break
      }
    }
  }
}

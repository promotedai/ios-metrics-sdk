import FirebaseRemoteConfig
import Foundation

#if !COCOAPODS
import PromotedCore
#endif

final class FirebaseRemoteConfigConnection: RemoteConfigConnection {

  func fetchClientConfig(
    initialConfig: ClientConfig,
    callback: @escaping Callback
  ) throws {
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
        var warnings: [String] = []
        var infos: [String] = []
        let config = ClientConfig(initialConfig)
        config.merge(
          from: remoteConfig, warnings: &warnings, infos: &infos
        )
        callback(config, nil)
      case .failure, .noFetchYet:
        callback(nil, nil)
      case .throttled:
        callback(nil, nil)
      @unknown default:
        callback(nil, nil)
      }
    }
  }
}

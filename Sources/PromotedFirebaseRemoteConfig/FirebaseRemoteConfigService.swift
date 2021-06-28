import FirebaseRemoteConfig
import Foundation

#if !COCOAPODS
import PromotedCore
#endif

final class FirebaseRemoteConfigService: ClientConfigService {

  var config: ClientConfig {
    ClientConfig()
  }

  func fetchClientConfig() throws {
    let remoteConfig = RemoteConfig.remoteConfig()
    #if DEBUG
      let settings = RemoteConfigSettings()
      settings.minimumFetchInterval = 0
      remoteConfig.configSettings = settings
    #endif
    remoteConfig.activate { changed, error in
      remoteConfig.configValue(forKey: <#T##String?#>, source: <#T##RemoteConfigSource#>)
    }
    remoteConfig.fetch { status, error in

    }
  }

  func addClientConfigListener(_ listener: ClientConfigListener) {
    <#code#>
  }

  func removeClientConfigListener(_ listener: ClientConfigListener) {
    <#code#>
  }
}

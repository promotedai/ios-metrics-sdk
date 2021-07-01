import Firebase
import FirebaseRemoteConfig
import Foundation

#if !COCOAPODS
import PromotedCore
#endif

final class FirebaseRemoteConfigConnection: RemoteConfigConnection {

  private let firebaseApp: FirebaseApp

  init(app: FirebaseApp) {
    self.firebaseApp = app
  }

  func fetchClientConfig(
    initialConfig: ClientConfig,
    callback: @escaping Callback
  ) {
    let remoteConfig = RemoteConfig.remoteConfig(app: firebaseApp)
    #if DEBUG
      let settings = RemoteConfigSettings()
      settings.minimumFetchInterval = 0
      remoteConfig.configSettings = settings
    #endif
    remoteConfig.fetch { status, error in
      var resultConfig: ClientConfig? = nil
      var resultError: RemoteConfigConnectionError? = nil
      var resultMessages = PendingLogMessages()
      defer {
        let result = Result(
          config: resultConfig,
          error: resultError,
          messages: resultMessages
        )
        callback(result)
      }
      if let error = error {
        resultError = .failed(underlying: error)
        return
      }
      switch status {
      case .success:
        let config = ClientConfig(initialConfig)
        config.merge(from: remoteConfig, messages: &resultMessages)
        resultConfig = config
      case .failure, .noFetchYet:
        resultError = .failed(underlying: nil)
      case .throttled:
        resultError = .throttled
      @unknown default:
        resultError = .unknown
      }
    }
  }
}

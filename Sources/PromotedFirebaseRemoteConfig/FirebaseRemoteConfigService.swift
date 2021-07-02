import Firebase
import Foundation

#if SWIFT_PACKAGE
import FirebaseRemoteConfig
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
    remoteConfig.fetchAndActivate { status, error in
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
      case .successUsingPreFetchedData:
        resultMessages.info("Using prefetched config.", visibility: .public)
        fallthrough
      case .successFetchedFromRemote:
        let config = ClientConfig(initialConfig)
        config.merge(from: remoteConfig, messages: &resultMessages)
        resultConfig = config
        resultMessages.info(
          "Remote config successfully fetched and merged.",
          visibility: .public
        )
      case .error:
        resultError = .failed(underlying: nil)
      @unknown default:
        resultError = .unknown
      }
    }
  }
}

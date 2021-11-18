import Firebase
import Foundation

#if SWIFT_PACKAGE
import FirebaseRemoteConfig
import PromotedCore
#endif

final class FirebaseRemoteConfigConnection: RemoteConfigConnection {

  private let plistFilename: String?
  private var cachedFirebaseApp: FirebaseApp?

  init(app: FirebaseApp) {
    self.plistFilename = nil
    self.cachedFirebaseApp = app
  }

  init(plistFilename: String) {
    self.plistFilename = plistFilename
    self.cachedFirebaseApp = nil
  }

  private func firebaseApp() throws -> FirebaseApp {
    // Use existing cached app, if available.
    if let existingApp = cachedFirebaseApp { return existingApp }

    // If the app has already been configured in Firebase, re-use it.
    // React Native under debug tries to run initialization code multiple
    // times, and trying to configure the same Firebase app more than
    // once causes an error.
    guard let plistFilename = plistFilename else {
      throw RemoteConfigConnectionError.serviceConfigError(
        "Expected either app or plistFilename specified"
      )
    }
    if let existingApp = FirebaseApp.app(name: plistFilename) {
      cachedFirebaseApp = existingApp
      return existingApp
    }

    // Load options from bundled plist, configure, and cache result.
    guard let appConfigPath = Bundle.main.path(
      forResource: plistFilename,
      ofType: "plist"
    ) else {
      throw RemoteConfigConnectionError.serviceConfigError(
        "PList named \(plistFilename) not found"
      )
    }
    guard let firebaseOptions = FirebaseOptions(
      contentsOfFile: appConfigPath
    ) else {
      throw RemoteConfigConnectionError.serviceConfigError(
        "Could not create FirebaseOptions from plist file at \(appConfigPath)"
      )
    }
    FirebaseApp.configure(name: plistFilename, options: firebaseOptions)
    cachedFirebaseApp = FirebaseApp.app(name: plistFilename)
    return cachedFirebaseApp!
  }

  func fetchClientConfig(
    initialConfig: ClientConfig,
    callback: @escaping Callback
  ) throws {
    let remoteConfig = RemoteConfig.remoteConfig(app: try firebaseApp())
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
        var config = initialConfig
        config.merge(from: remoteConfig, messages: &resultMessages)
        resultConfig = config
        resultMessages.info(
          "Remote config successfully fetched and merged.",
          visibility: .public
        )
      case .error:
        resultError = .failed(underlying: nil)
      @unknown default:
        resultError = .failed(underlying: nil)
      }
    }
  }
}

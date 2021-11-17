import Firebase
import Foundation

#if SWIFT_PACKAGE
import PromotedCore
#endif

@objc public extension ModuleConfig {

  private class FirebaseConnectionWrapper: RemoteConfigConnection {
    private let firebaseApp: FirebaseApp
    private lazy var connection: RemoteConfigConnection =
      FirebaseRemoteConfigConnection(app: firebaseApp)

    init(app: FirebaseApp) {
      self.firebaseApp = app
    }

    func fetchClientConfig(
      initialConfig: ClientConfig,
      callback: @escaping Callback
    ) {
      connection.fetchClientConfig(
        initialConfig: initialConfig,
        callback: callback
      )
    }
  }

  /// Uses Firebase Remote Config to load remote `ClientConfig`.
  @objc func useFirebaseRemoteConfigWithDefaultApp() {
    if let defaultApp = FirebaseApp.app() {
      useFirebaseRemoteConfig(app: defaultApp)
    }
  }

  @objc func useFirebaseRemoteConfig(app: FirebaseApp) {
    remoteConfigConnection = FirebaseConnectionWrapper(app: app)
  }
}

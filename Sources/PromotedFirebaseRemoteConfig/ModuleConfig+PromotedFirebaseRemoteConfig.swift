import Firebase
import Foundation

#if SWIFT_PACKAGE
import PromotedCore
#endif

@objc public extension ModuleConfig {

  /// Uses Firebase Remote Config to load remote `ClientConfig`.
  @objc func useFirebaseRemoteConfigWithDefaultApp() {
    if let defaultApp = FirebaseApp.app() {
      useFirebaseRemoteConfig(app: defaultApp)
    }
  }

  @objc func useFirebaseRemoteConfig(app: FirebaseApp) {
    remoteConfigConnection = FirebaseRemoteConfigConnection(app: app)
  }

  @objc func useFirebaseRemoteConfig(plistFilename: String) {
    remoteConfigConnection = FirebaseRemoteConfigConnection(
      plistFilename: plistFilename
    )
  }
}

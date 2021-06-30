import Foundation

#if !COCOAPODS
import PromotedCore
#endif

@objc public extension ModuleConfig {

  /// Uses Firebase Remote Config to load remote `ClientConfig`.
  @objc func useFirebaseRemoteConfig() {
    remoteConfigConnection = FirebaseRemoteConfigConnection()
  }
}

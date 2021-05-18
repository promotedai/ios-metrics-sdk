import Foundation

#if !COCOAPODS
import PromotedCore
#endif

@objc public extension ModuleConfig {
  @objc func useFirebaseAnalyticsWithGlobalApp() {
    analyticsConnection = FirebaseAnalyticsConnection()
  }

  @objc func useFirebaseAnalytics(configFilename: String) {
    analyticsConnection = FirebaseAnalyticsConnection(configFilename: configFilename)
  }
}

import Foundation

#if SWIFT_PACKAGE
import PromotedCore
#endif

@objc public extension ModuleConfig {

  /// Uses Firebase Analytics with default app to log analytics.
  @objc func useFirebaseAnalytics() {
    analyticsConnection = FirebaseAnalyticsConnection()
  }
}

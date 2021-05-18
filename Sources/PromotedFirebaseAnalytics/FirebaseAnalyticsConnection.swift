import Firebase
import Foundation

#if !COCOAPODS
import PromotedCore
#endif

/**
 Sends analytics through Firebase Analytics.

 - Event counts are logged with key `event-count`.
 - Bytes sent is logged with key `bytes-sent`.
 - Errors are logged with key `errors`.

 Firebase Analytics only logs to the default app.
 */
final class FirebaseAnalyticsConnection: AnalyticsConnection {

  func startServices() throws {}

  func log(eventCount: Int) {
    FirebaseAnalytics.Analytics.logEvent("event-count", parameters: [
      AnalyticsParameterValue: eventCount
    ])
  }

  func log(bytesSent: UInt64) {
    FirebaseAnalytics.Analytics.logEvent("bytes-sent", parameters: [
      AnalyticsParameterValue: bytesSent
    ])
  }

  func log(errors: [Error]) {
    for error in errors {
      guard let externalError = error.asExternalError() as? NSErrorProperties else { continue }
      FirebaseAnalytics.Analytics.logEvent("error", parameters: [
        "description": externalError.debugDescription,
        "domain": externalError.domain,
        "error-code": externalError.code
      ])
    }
  }
}

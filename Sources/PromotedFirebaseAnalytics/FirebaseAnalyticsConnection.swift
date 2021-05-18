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
    Firebase.Analytics.logEvent("ai-promoted-event-count", parameters: [
      AnalyticsParameterValue: eventCount
    ])
  }

  func log(bytesSent: UInt64) {
    Firebase.Analytics.logEvent("ai-promoted-bytes-sent", parameters: [
      AnalyticsParameterValue: bytesSent
    ])
  }

  func log(errors: [Error]) {
    for error in errors {
      guard let externalError = error.asExternalError() as? NSErrorProperties else { continue }
      Firebase.Analytics.logEvent("ai-promoted-error", parameters: [
        "description": externalError.debugDescription.prefix(100),
        "domain": externalError.domain,
        "error-code": externalError.code
      ])
    }
  }
}

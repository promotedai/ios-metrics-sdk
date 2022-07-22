import Firebase
import Foundation

#if SWIFT_PACKAGE
import PromotedCore
#endif

/**
 Sends analytics through Firebase Analytics.

 - Event counts are logged with key `ai_promoted_event_count`.
 - Bytes sent is logged with key `ai_promoted_bytes_sent`.
 - Errors are logged with key `ai_promoted_error`.

 Firebase Analytics only logs to the default app.
 */
final class FirebaseAnalyticsConnection: AnalyticsConnection {

  func startServices() throws {}

  func log(eventCount: Int) {
    Firebase.Analytics.logEvent("ai_promoted_event_count", parameters: [
      AnalyticsParameterValue: eventCount
    ])
  }

  func log(bytesSent: UInt64) {
    Firebase.Analytics.logEvent("ai_promoted_bytes_sent", parameters: [
      AnalyticsParameterValue: bytesSent
    ])
  }

  func log(errors: [Error]) {
    for error in errors {
      if let externalError = error.asErrorProperties() {
        Firebase.Analytics.logEvent("ai_promoted_error", parameters: [
          "description": externalError.externalDescription.prefix(100),
          "domain": externalError.domain,
          "error-code": externalError.code
        ])
      }
    }
  }
}

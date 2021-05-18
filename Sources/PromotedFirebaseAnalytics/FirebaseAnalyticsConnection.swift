import Firebase
import Foundation

#if !COCOAPODS
import PromotedCore
#endif

final class FirebaseAnalyticsConnection: AnalyticsConnection {

  private let configFilename: String?

  init() {
    self.configFilename = nil
  }

  init(configFilename: String) {
    self.configFilename = configFilename
  }

  func startServices() throws {
    if configFilename == nil { return }
    let path = Bundle.main.path(forResource: configFilename, ofType: "plist")
    guard let path = path,
          let options = FirebaseOptions(contentsOfFile: path) else {
      return
    }
    FirebaseApp.configure(options: options)
  }

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

import Foundation

@testable import PromotedCore

final class FakeAnalyticsConnection: AnalyticsConnection {

  var lastEventCount: Int
  var lastBytesSent: UInt64
  var lastErrors: [Error]

  init() {
    lastEventCount = 0
    lastBytesSent = 0
    lastErrors = []
  }

  func startServices() throws {}

  func log(eventCount: Int) {
    lastEventCount = eventCount
  }
  
  func log(bytesSent: UInt64) {
    lastBytesSent = bytesSent
  }
  
  func log(errors: [Error]) {
    lastErrors = errors
  }
  
  func reset() {
    lastEventCount = 0
    lastBytesSent = 0
    lastErrors = []
  }
}

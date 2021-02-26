import Foundation
@testable import PromotedAIMetricsSDK

class FakeClock: Clock {
  var now: TimeInterval
  init(now: TimeInterval = 0.0) { self.now = now }
}

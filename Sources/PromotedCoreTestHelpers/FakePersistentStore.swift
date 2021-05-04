import Foundation

@testable import PromotedAIMetricsSDK

class FakePersistentStore: PersistentStore {
  var userID: String? = nil
  var logUserID: String? = nil
  var clientConfigMessage: Data? = nil
  init() {}
}

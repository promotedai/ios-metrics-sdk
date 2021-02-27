import Foundation
@testable import PromotedAIMetricsSDK

class FakePersistentStore: PersistentStore {
  var userID: String?
  var logUserID: String?
  var clientConfigMessage: Data?
}

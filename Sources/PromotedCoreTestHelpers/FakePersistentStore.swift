import Foundation

@testable import PromotedCore

class FakePersistentStore: PersistentStore {
  var userID: String? = nil
  var logUserID: String? = nil
  var clientConfigMessage: Data? = nil
  init() {}
}

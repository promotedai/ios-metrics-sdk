import Foundation

@testable import PromotedCore

final class FakePersistentStore: PersistentStore {
  var userID: String? = nil
  var logUserID: String? = nil
  var clientConfigMessage: Data? = nil
  init() {}
}

import Foundation

@testable import PromotedCore

final class FakePersistentStore: PersistentStore {
  var userID: String? = nil
  var logUserID: String? = nil
  var clientConfig: ConfigDict? = nil
}

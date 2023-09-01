import Foundation

@testable import PromotedCore

final class FakePersistentStore: PersistentStore {
  var userID: String? = nil
  var anonUserID: String? = nil
  var clientConfig: Data? = nil
}

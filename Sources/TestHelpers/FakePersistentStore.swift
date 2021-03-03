import Foundation
import PromotedAIMetricsSDK

public class FakePersistentStore: PersistentStore {
  public var userID: String? = nil
  public var logUserID: String? = nil
  public var clientConfigMessage: Data? = nil
  public init() {}
}

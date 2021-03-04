import Foundation
import PromotedAIMetricsSDK

public class FakeIDMap: AbstractIDMap {
  public override func deterministicUUIDString(value: String?) -> String {
    return String(format: "%02x", (value?.hashValue ?? 0))
  }
  public override func logUserID(userID: String?) -> String {
    return deterministicUUIDString(value: userID)
  }
  public override func clickID() -> String {
    return "fake-click-id"
  }
}
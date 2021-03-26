import Foundation
import PromotedAIMetricsSDK

public class FakeIDMap: AbstractIDMap {
  public override func deterministicUUIDString(value: String?) -> String {
    return String(format: "%02x", (value?.hashValue ?? 0))
  }
  public override func logUserID(userID: String?) -> String {
    return deterministicUUIDString(value: userID)
  }
  public override func actionID() -> String {
    return "fake-action-id"
  }
  public override func sessionID() -> String {
    return "fake-session-id"
  }
}

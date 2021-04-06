import Foundation
import PromotedAIMetricsSDK

public class FakeIDMap: AbstractIDMap {
  public var incrementCounts: Bool = false
  
  public override func deterministicUUIDString(value: String?) -> String {
    return String(format: "%02x", (value?.hashValue ?? 0))
  }

  public private(set) var logUserIDCount: Int = 0
  public override func logUserID() -> String {
    if incrementCounts {
      logUserIDCount += 1
      return "fake-log-user-id-\(logUserIDCount)"
    }
    return "fake-log-user-id"
  }

  public private(set) var actionIDCount: Int = 0
  public override func actionID() -> String {
    if incrementCounts {
      actionIDCount += 1
      return "fake-action-id-\(actionIDCount)"
    }
    return "fake-action-id"
  }

  public private(set) var sessionIDCount: Int = 0
  public override func sessionID() -> String {
    if incrementCounts {
      sessionIDCount += 1
      return "fake-session-id-\(sessionIDCount)"
    }
    return "fake-session-id"
  }
  
  public private(set) var viewIDCount: Int = 0
  public override func viewID() -> String {
    if incrementCounts {
      viewIDCount += 1
      return "fake-view-id-\(viewIDCount)"
    }
    return "fake-view-id"
  }
}

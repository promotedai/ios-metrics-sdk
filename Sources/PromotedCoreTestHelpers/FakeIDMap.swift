import Foundation

@testable import PromotedCore

class FakeIDMap: AbstractIDMap {
  var incrementCounts: Bool = false
  
  override func deterministicUUIDString(value: String?) -> String {
    return String(format: "%02x", (value?.hashValue ?? 0))
  }

  private(set) var logUserIDCount: Int = 0
  override func logUserID() -> String {
    if incrementCounts {
      logUserIDCount += 1
      return "fake-log-user-id-\(logUserIDCount)"
    }
    return "fake-log-user-id"
  }

  private(set) var actionIDCount: Int = 0
  override func actionID() -> String {
    if incrementCounts {
      actionIDCount += 1
      return "fake-action-id-\(actionIDCount)"
    }
    return "fake-action-id"
  }

  private(set) var sessionIDCount: Int = 0
  override func sessionID() -> String {
    if incrementCounts {
      sessionIDCount += 1
      return "fake-session-id-\(sessionIDCount)"
    }
    return "fake-session-id"
  }
  
  private(set) var viewIDCount: Int = 0
  override func viewID() -> String {
    if incrementCounts {
      viewIDCount += 1
      return "fake-view-id-\(viewIDCount)"
    }
    return "fake-view-id"
  }
}

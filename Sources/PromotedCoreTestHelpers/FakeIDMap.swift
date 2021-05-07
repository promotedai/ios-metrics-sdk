import Foundation

@testable import PromotedCore

final class FakeIDMap: IDMap {

  var incrementCounts: Bool = false

  private(set) var logUserIDCount: Int = 0
  func logUserID() -> String {
    if incrementCounts {
      logUserIDCount += 1
      return "fake-log-user-id-\(logUserIDCount)"
    }
    return "fake-log-user-id"
  }

  private(set) var sessionIDCount: Int = 0
  func sessionID() -> String {
    if incrementCounts {
      sessionIDCount += 1
      return "fake-session-id-\(sessionIDCount)"
    }
    return "fake-session-id"
  }

  private(set) var impressionIDCount: Int = 0
  func impressionID() -> String {
    if incrementCounts {
      impressionIDCount += 1
      return "fake-impression-id-\(impressionIDCount)"
    }
    return "fake-impression-id"
  }

  func contentID(clientID: String) -> String { clientID }

  private(set) var actionIDCount: Int = 0
  func actionID() -> String {
    if incrementCounts {
      actionIDCount += 1
      return "fake-action-id-\(actionIDCount)"
    }
    return "fake-action-id"
  }

  private(set) var viewIDCount: Int = 0
  func viewID() -> String {
    if incrementCounts {
      viewIDCount += 1
      return "fake-view-id-\(viewIDCount)"
    }
    return "fake-view-id"
  }
}

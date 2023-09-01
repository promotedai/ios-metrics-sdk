import Foundation
import XCTest

@testable import PromotedCore
@testable import PromotedCoreTestHelpers

final class ScrollTrackerTests: ModuleTestCase {
  
  private var metricsLogger: MetricsLogger!
  private var scrollTracker: ScrollTracker!
  
  override func setUp() {
    super.setUp()
    idMap.incrementCounts = true
    store.userID = "foobar"
    store.anonUserID = "fake-anon-user-id"
    metricsLogger = MetricsLogger(deps: module)
    metricsLogger.startSessionForTesting(userID: "foo")
    scrollTracker = ScrollTracker(
      metricsLogger: metricsLogger,
      sourceType: .clientBackend,
      deps: module
    )
  }

  func testSetViewport() {
    scrollTracker.setFrame(
      CGRect(x: 0, y: 0, width: 20, height: 20),
      forContent: Content(contentID: "id0")
    )
    scrollTracker.setFrame(
      CGRect(x: 0, y: 20, width: 20, height: 20),
      forContent: Content(contentID: "id1")
    )
    scrollTracker.setFrame(
      CGRect(x: 0, y: 40, width: 20, height: 20),
      forContent: Content(contentID: "id2")
    )
    
    // Top two views on screen, second view is 50% visible.
    do {
      func assertEqualUnordered(_ expected: [String], _ actual: [String]) {
        XCTAssertEqual(Set(expected), Set(actual))
      }
      scrollTracker.viewport = CGRect(x: 0, y: 0, width: 20, height: 30)
      clock.advance(to: 1)
      let logMessages = metricsLogger.logMessagesForTesting
      XCTAssertEqual(2, logMessages.count)
      let impression0 = logMessages[0] as! Event_Impression
      let impression1 = logMessages[1] as! Event_Impression
      assertEqualUnordered(
        ["fake-impression-id-1", "fake-impression-id-2"],
        [impression0.impressionID, impression1.impressionID]
      )
      assertEqualUnordered(
        ["id0", "id1"],
        [impression0.contentID, impression1.contentID]
      )
    }

    // Reset viewport to force all views visible on next pass.
    scrollTracker.viewport = CGRect.zero
    clock.advance(to: 2)
    metricsLogger.flush()
    
    // Middle view on screen.
    do {
      scrollTracker.viewport = CGRect(x: 0, y: 20, width: 20, height: 20)
      clock.advance(to: 3)
      let logMessages = metricsLogger.logMessagesForTesting
      XCTAssertEqual(1, logMessages.count)
      let impression = logMessages[0] as! Event_Impression
      // This should generate a new impressionID.
      XCTAssertEqual("fake-impression-id-3", impression.impressionID)
      XCTAssertEqual("id1", impression.contentID)
    }
  }
  
  func testSetViewportItemNotOnScreen() {
    scrollTracker.setFrame(
      CGRect(x: 0, y: 0, width: 20, height: 20),
      forContent: Content(contentID: "id0")
    )
    scrollTracker.setFrame(
      CGRect(x: 0, y: 20, width: 20, height: 20),
      forContent: Content(contentID: "id1")
    )
    scrollTracker.setFrame(
      CGRect(x: 0, y: 40, width: 20, height: 20),
      forContent: Content(contentID: "id2")
    )

    // Item "id1" is not more than 50% on screen.
    scrollTracker.viewport = CGRect(x: 0, y: 0, width: 20, height: 25)
    clock.advance(to: 1)
    let logMessages = metricsLogger.logMessagesForTesting
    XCTAssertEqual(1, logMessages.count)
    let impression0 = logMessages[0] as! Event_Impression
    XCTAssertEqual("fake-impression-id-1", impression0.impressionID)
    XCTAssertEqual("id0", impression0.contentID)
  }
  
  /// Make sure that frames with 0 area don't cause division by 0.
  func testZeroAreaFrame() {
    scrollTracker.setFrame(
      CGRect(x: 0, y: 0, width: 20, height: 0),
      forContent: Content(contentID: "id0")
    )
    scrollTracker.setFrame(
      CGRect(x: 0, y: 20, width: 20, height: 0),
      forContent: Content(contentID: "id1")
    )
    scrollTracker.setFrame(
      CGRect(x: 0, y: 40, width: 20, height: 0),
      forContent: Content(contentID: "id2")
    )

    scrollTracker.viewport = CGRect(x: 0, y: 0, width: 20, height: 25)
    clock.advance(to: 1)
    XCTAssertEqual(0, metricsLogger.logMessagesForTesting.count)
  }
}

import Foundation
import TestHelpers
import XCTest

@testable import PromotedAIMetricsSDK
@testable import TestHelpers

final class ScrollTrackerTests: XCTestCase {
  
  private var clock: FakeClock?
  private var config: ClientConfig?
  private var idMap: FakeIDMap?
  private var store: FakePersistentStore?
  private var metricsLogger: MetricsLogger?
  private var scrollTracker: ScrollTracker?
  
  public override func setUp() {
    super.setUp()
    clock = FakeClock()
    config = ClientConfig()
    idMap = FakeIDMap()
    store = FakePersistentStore()
    store!.userID = "foobar"
    store!.logUserID = "fake-log-user-id"
    metricsLogger = MetricsLogger(clientConfig: config!,
                                  clock: clock!,
                                  connection: FakeNetworkConnection(),
                                  deviceInfo: FakeDeviceInfo(),
                                  idMap: idMap!,
                                  store: store!)
    metricsLogger!.startSessionForTesting(userID: "foo")
    scrollTracker = ScrollTracker(metricsLogger: metricsLogger!,
                                  clientConfig: config!,
                                  clock: clock!)
  }

  func testSetViewport() {
    scrollTracker!.setFrame(CGRect(x: 0, y: 0, width: 20, height: 20),
                            forContent: Content(contentID: "id0"))
    scrollTracker!.setFrame(CGRect(x: 0, y: 20, width: 20, height: 20),
                            forContent: Content(contentID: "id1"))
    scrollTracker!.setFrame(CGRect(x: 0, y: 40, width: 20, height: 20),
                            forContent: Content(contentID: "id2"))
    
    // Top two views on screen, second view is 50% visible.
    do {
      scrollTracker!.viewport = CGRect(x: 0, y: 0, width: 20, height: 30)
      clock!.advance(to: 1)
      let logMessages = metricsLogger!.logMessagesForTesting
      XCTAssertEqual(2, logMessages.count)
      let impression0 = logMessages[0] as! Event_Impression
      let impression1 = logMessages[1] as! Event_Impression
      let actualSet = Set(arrayLiteral: impression0.impressionID, impression1.impressionID)
      let expectedSet = Set(arrayLiteral:
          idMap!.impressionIDOrNil(insertionID: nil,
                                   contentID: "id0",
                                   logUserID: "fake-log-user-id"),
          idMap!.impressionIDOrNil(insertionID: nil,
                                   contentID: "id1",
                                   logUserID: "fake-log-user-id"))
      XCTAssertEqual(expectedSet, actualSet)
    }

    // Reset viewport to force all views visible on next pass.
    scrollTracker!.viewport = CGRect.zero
    clock!.advance(to: 2)
    metricsLogger!.flush()
    
    // Middle view on screen.
    do {
      scrollTracker!.viewport = CGRect(x: 0, y: 20, width: 20, height: 20)
      clock!.advance(to: 3)
      let logMessages = metricsLogger!.logMessagesForTesting
      XCTAssertEqual(1, logMessages.count)
      let impression = logMessages[0] as! Event_Impression
      XCTAssertEqual(idMap?.impressionIDOrNil(insertionID: nil,
                                              contentID: "id1",
                                              logUserID: "fake-log-user-id"),
                     impression.impressionID)
    }
  }
  
  func testSetViewportItemNotOnScreen() {
    scrollTracker!.setFrame(CGRect(x: 0, y: 0, width: 20, height: 20),
                            forContent: Content(contentID: "id0"))
    scrollTracker!.setFrame(CGRect(x: 0, y: 20, width: 20, height: 20),
                            forContent: Content(contentID: "id1"))
    scrollTracker!.setFrame(CGRect(x: 0, y: 40, width: 20, height: 20),
                            forContent: Content(contentID: "id2"))

    // Item "id1" is not more than 50% on screen.
    scrollTracker!.viewport = CGRect(x: 0, y: 0, width: 20, height: 25)
    clock!.advance(to: 1)
    let logMessages = metricsLogger!.logMessagesForTesting
    XCTAssertEqual(1, logMessages.count)
    let impression0 = logMessages[0] as! Event_Impression
    XCTAssertEqual(idMap?.impressionIDOrNil(insertionID: nil,
                                            contentID: "id0",
                                            logUserID: "fake-log-user-id"),
                   impression0.impressionID)
  }
  
  /// Make sure that frames with 0 area don't cause division by 0.
  func testZeroAreaFrame() {
    scrollTracker!.setFrame(CGRect(x: 0, y: 0, width: 20, height: 0),
                            forContent: Content(contentID: "id0"))
    scrollTracker!.setFrame(CGRect(x: 0, y: 20, width: 20, height: 0),
                            forContent: Content(contentID: "id1"))
    scrollTracker!.setFrame(CGRect(x: 0, y: 40, width: 20, height: 0),
                            forContent: Content(contentID: "id2"))

    scrollTracker!.viewport = CGRect(x: 0, y: 0, width: 20, height: 25)
    clock!.advance(to: 1)
    XCTAssertEqual(0, metricsLogger!.logMessagesForTesting.count)
  }
  
  static var allTests = [
    ("testSetViewport", testSetViewport),
    ("testSetViewportItemNotOnScreen", testSetViewportItemNotOnScreen),
    ("testZeroAreaFrame", testZeroAreaFrame),
  ]
}

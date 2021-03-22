import Foundation
import TestHelpers
import XCTest

@testable import PromotedAIMetricsSDK
@testable import TestHelpers

final class ScrollTrackerTests: XCTestCase {
  
  private var clock: FakeClock?
  private var idMap: IDMap?
  private var metricsLogger: MetricsLogger?
  private var scrollTracker: ScrollTracker?
  
  public override func setUp() {
    super.setUp()
    clock = FakeClock()
    idMap = SHA1IDMap.instance
    metricsLogger = MetricsLogger(clientConfig: ClientConfig(),
                                  clock: clock!,
                                  connection: FakeNetworkConnection(),
                                  idMap: idMap!,
                                  store: FakePersistentStore())
    scrollTracker = ScrollTracker(metricsLogger: metricsLogger!,
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
    scrollTracker!.viewport = CGRect(x: 0, y: 0, width: 20, height: 30)
    clock!.advance(to: 1)
    XCTAssertEqual(2, metricsLogger!.logMessages.count)
    let impression0 = metricsLogger!.logMessages[0] as! Event_Impression
    let impression1 = metricsLogger!.logMessages[1] as! Event_Impression
    let actualSet = Set(arrayLiteral: impression0.impressionID, impression1.impressionID)
    let expectedSet = Set(arrayLiteral: idMap!.impressionID(contentID: "id0"),
                          idMap!.impressionID(contentID: "id1"))
    XCTAssertEqual(expectedSet, actualSet)

    // Reset viewport to force all views visible on next pass.
    scrollTracker!.viewport = CGRect.zero
    clock!.advance(to: 2)
    metricsLogger!.flush()
    
    // Middle view on screen.
    scrollTracker!.viewport = CGRect(x: 0, y: 20, width: 20, height: 20)
    clock!.advance(to: 3)
    XCTAssertEqual(1, metricsLogger!.logMessages.count)
    let impression = metricsLogger!.logMessages[0] as! Event_Impression
    XCTAssertEqual(idMap?.impressionID(contentID: "id1"), impression.impressionID)
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
    XCTAssertEqual(1, metricsLogger!.logMessages.count)
    let impression0 = metricsLogger!.logMessages[0] as! Event_Impression
    XCTAssertEqual(idMap?.impressionID(contentID: "id0"), impression0.impressionID)
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
    XCTAssertEqual(0, metricsLogger!.logMessages.count)
  }
  
  static var allTests = [
    ("testSetViewport", testSetViewport),
    ("testSetViewportItemNotOnScreen", testSetViewportItemNotOnScreen),
    ("testZeroAreaFrame", testZeroAreaFrame),
  ]
}

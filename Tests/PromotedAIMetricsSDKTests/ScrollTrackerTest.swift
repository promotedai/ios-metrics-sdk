import Foundation
import TestHelpers
import XCTest

@testable import PromotedAIMetricsSDK
@testable import TestHelpers

final class ScrollTrackerTests: XCTestCase {
  
  private var data: [[Content]]?
  private var clock: FakeClock?
  private var idMap: IDMap?
  private var metricsLogger: MetricsLogger?
  private var impressionLogger: ImpressionLogger?
  private var scrollTracker: ScrollTracker?
  
  public override func setUp() {
    super.setUp()
    clock = FakeClock()
    idMap = SHA1IDMap.instance
    metricsLogger = MetricsLogger(messageProvider: FakeMessageProvider(),
                                  clientConfig: ClientConfig(),
                                  clock: clock!,
                                  connection: FakeNetworkConnection(),
                                  idMap: idMap!,
                                  store: FakePersistentStore())
    data = [[Content(contentID: "id0")], [Content(contentID: "id1"), Content(contentID: "id2")]]
    impressionLogger = ImpressionLogger(sectionedContent: data!,
                                        metricsLogger: metricsLogger!,
                                        clock: clock!)
    scrollTracker = ScrollTracker(sectionedContent: data!,
                                  impressionLogger: impressionLogger!,
                                  clock: clock!)
  }

  func testSetFrame() {
    scrollTracker!.setFrame(CGRect(x: 10, y: 10, width: 20, height: 20),
                            forContentAtIndex: IndexPath(indexes: [0, 0]))
    scrollTracker!.setFrame(CGRect(x: 50, y: 50, width: 100, height: 100),
                            forContent: Content(contentID: "id1"))
    XCTAssertEqual(CGRect(x: 10, y: 10, width: 20, height: 20),
                   scrollTracker!.frames[0][0])
    XCTAssertEqual(CGRect(x: 50, y: 50, width: 100, height: 100),
                   scrollTracker!.frames[1][0])
    XCTAssertEqual(CGRect.zero, scrollTracker!.frames[1][1])
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
    XCTAssertEqual(idMap?.impressionID(contentID: "id0"), impression0.impressionID)
    let impression1 = metricsLogger!.logMessages[1] as! Event_Impression
    XCTAssertEqual(idMap?.impressionID(contentID: "id1"), impression1.impressionID)
    impressionLogger!.collectionViewDidHideAllContent()
    metricsLogger!.flush()
    
    // Middle view on screen.
    scrollTracker!.viewport = CGRect(x: 0, y: 20, width: 20, height: 20)
    clock!.advance(to: 2)
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
    ("testSetFrame", testSetFrame),
    ("testSetViewport", testSetViewport),
    ("testSetViewportItemNotOnScreen", testSetViewportItemNotOnScreen),
    ("testZeroAreaFrame", testZeroAreaFrame),
  ]
}

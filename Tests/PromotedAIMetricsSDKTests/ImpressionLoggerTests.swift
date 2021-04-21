import Foundation
import TestHelpers
import XCTest

@testable import PromotedAIMetricsSDK
@testable import TestHelpers

final class ImpressionLoggerTests: XCTestCase {

  class Delegate: ImpressionLoggerDelegate {
    var startImpressions: [ImpressionLogger.Impression]
    var endImpressions: [ImpressionLogger.Impression]
    init() {
      startImpressions = []
      endImpressions = []
    }
    func clear() {
      startImpressions.removeAll()
      endImpressions.removeAll()
    }
    func impressionLogger(_ impressionLogger: ImpressionLogger,
                          didStartImpressions impressions: [ImpressionLogger.Impression]) {
      startImpressions.append(contentsOf: impressions)
    }
    
    func impressionLogger(_ impressionLogger: ImpressionLogger,
                          didEndImpressions impressions: [ImpressionLogger.Impression]) {
      endImpressions.append(contentsOf: impressions)
    }
  }
  
  private func content(_ contentID: String) -> Content {
    return Content(contentID: contentID)
  }
  
  private func impression(_ contentID: String,
                          _ startTime: TimeInterval,
                          _ endTime: TimeInterval = -1.0) -> ImpressionLogger.Impression {
    let content = Content(contentID: contentID)
    return ImpressionLogger.Impression(content: content, startTime: startTime, endTime: endTime)
  }

  /** Asserts that list contents are equal regardless of order. */
  func assertContentsEqual(_ a: [ImpressionLogger.Impression],
                           _ b: [ImpressionLogger.Impression]) {
    XCTAssertEqual(Set(a), Set(b))
  }
  
  private var clock: FakeClock?
  private var delegate: Delegate?
  private var idMap: IDMap?
  private var metricsLogger: MetricsLogger?
  private var impressionLogger: ImpressionLogger?
  
  override func setUp() {
    super.setUp()
    clock = FakeClock()
    delegate = Delegate()
    idMap = SHA1IDMap.instance
    metricsLogger = MetricsLogger(clientConfig: ClientConfig(),
                                  clock: clock!,
                                  connection: FakeNetworkConnection(),
                                  deviceInfo: FakeDeviceInfo(),
                                  idMap: idMap!,
                                  osLog: nil,
                                  store: FakePersistentStore(),
                                  xray: nil)
    metricsLogger!.startSessionAndLogUser(userID: "foo")
    impressionLogger = ImpressionLogger(metricsLogger: metricsLogger!,
                                        clock: clock!)
    impressionLogger!.delegate = delegate
  }

  func testStartImpressions() {
    clock!.advance(to: 123)
    
    impressionLogger!.collectionViewWillDisplay(content: content("jeff"))
    assertContentsEqual(delegate!.startImpressions, [impression("jeff", 123)])
    
    delegate!.clear()
    clock!.now = 500
    impressionLogger!.collectionViewWillDisplay(content: content("britta"))
    clock!.now = 501
    impressionLogger!.collectionViewWillDisplay(content: content("troy"))
    clock!.now = 502
    impressionLogger!.collectionViewWillDisplay(content: content("abed"))
    assertContentsEqual(delegate!.startImpressions,
                        [impression("britta", 500),
                         impression("troy", 501),
                         impression("abed", 502)])
  }
  
  func testEndImpressions() {
    clock!.advance(to: 123)
    
    impressionLogger!.collectionViewWillDisplay(content: content("annie"))
    clock!.now = 200
    impressionLogger!.collectionViewDidHide(content: content("annie"))
    assertContentsEqual(delegate!.endImpressions, [impression("annie", 123, 200)])
  }
  
  func testDidChangeImpressions() {
    clock!.advance(to: 123)
    
    impressionLogger!.collectionViewWillDisplay(content: content("shirley"))
    impressionLogger!.collectionViewWillDisplay(content: content("pierce"))
    impressionLogger!.collectionViewWillDisplay(content: content("ben"))
    impressionLogger!.collectionViewWillDisplay(content: content("craig"))
    assertContentsEqual(delegate!.startImpressions,
                        [impression("shirley", 123),
                         impression("pierce", 123),
                         impression("ben", 123),
                         impression("craig", 123)])

    delegate!.clear()
    let visibleContent = [content("shirley"),
                          content("craig"),
                          content("troy"),
                          content("abed")]
    clock!.now = 200
    
    impressionLogger!.collectionViewDidChangeVisibleContent(visibleContent)
    assertContentsEqual(delegate!.startImpressions,
                        [impression("troy", 200), impression("abed", 200)])
    assertContentsEqual(delegate!.endImpressions,
                        [impression("pierce", 123, 200), impression("ben", 123, 200)])
  }
  
  func testDidHideAllImpressions() {
    clock!.advance(to: 123)
    
    impressionLogger!.collectionViewWillDisplay(content: content("jeff"))
    impressionLogger!.collectionViewWillDisplay(content: content("britta"))
    impressionLogger!.collectionViewWillDisplay(content: content("annie"))
    impressionLogger!.collectionViewWillDisplay(content: content("troy"))
    assertContentsEqual(delegate!.startImpressions,
                        [impression("jeff", 123),
                         impression("britta", 123),
                         impression("annie", 123),
                         impression("troy", 123)])

    delegate!.clear()
    clock!.now = 200
    
    impressionLogger!.collectionViewDidHideAllContent()
    assertContentsEqual(delegate!.startImpressions, [])
    assertContentsEqual(delegate!.endImpressions,
                        [impression("jeff", 123, 200),
                         impression("britta", 123, 200),
                         impression("annie", 123, 200),
                         impression("troy", 123, 200)])
  }
}

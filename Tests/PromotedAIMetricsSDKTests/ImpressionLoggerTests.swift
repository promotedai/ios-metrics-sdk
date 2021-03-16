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
  
  class DataSource: ImpressionLoggerDataSource {
    func impressionLoggerItem(at indexPath: IndexPath) -> Item? {
      return nil
    }
  }
  
  private func impression(_ item: IndexPath.Element,
                          _ startTime: TimeInterval,
                          _ endTime: TimeInterval = -1.0) -> ImpressionLogger.Impression {
    let path = IndexPath(index: item)
    return ImpressionLogger.Impression(path: path, startTime: startTime, endTime: endTime)
  }

  /** Asserts that list contents are equal regardless of order. */
  func assertContentsEqual(_ a: [ImpressionLogger.Impression],
                           _ b: [ImpressionLogger.Impression]) {
    XCTAssertEqual(Set(a), Set(b))
  }
  
  private var clock: FakeClock?
  private var dataSource: DataSource?
  private var delegate: Delegate?
  private var idMap: IDMap?
  private var metricsLogger: MetricsLogger?
  private var impressionLogger: ImpressionLogger?
  
  public override func setUp() {
    super.setUp()
    clock = FakeClock()
    dataSource = DataSource()
    delegate = Delegate()
    idMap = SHA1IDMap.instance
    metricsLogger = MetricsLogger(messageProvider: FakeMessageProvider(),
                                  clientConfig: ClientConfig(),
                                  clock: clock!,
                                  connection: FakeNetworkConnection(),
                                  idMap: idMap!,
                                  store: FakePersistentStore())
    impressionLogger = ImpressionLogger(dataSource: dataSource!,
                                        metricsLogger: metricsLogger!,
                                        clock: clock!)
    impressionLogger!.delegate = delegate
  }

  func testStartImpressions() {
    clock!.advance(to: 123)
    
    impressionLogger!.collectionViewWillDisplayContent(atIndex: IndexPath(index: 0))
    assertContentsEqual(delegate!.startImpressions, [impression(0, 123)])
    
    delegate!.clear()
    clock!.now = 500
    impressionLogger!.collectionViewWillDisplayContent(atIndex: IndexPath(index: 0))
    clock!.now = 501
    impressionLogger!.collectionViewWillDisplayContent(atIndex: IndexPath(index: 1))
    clock!.now = 502
    impressionLogger!.collectionViewWillDisplayContent(atIndex: IndexPath(index: 2))
    assertContentsEqual(delegate!.startImpressions,
                        [impression(0, 500), impression(1, 501), impression(2, 502)])
  }
  
  func testEndImpressions() {
    clock!.advance(to: 123)
    
    impressionLogger!.collectionViewWillDisplayContent(atIndex: IndexPath(index: 0))
    clock!.now = 200
    impressionLogger!.collectionViewDidHideContent(atIndex: IndexPath(index: 0))
    assertContentsEqual(delegate!.endImpressions, [impression(0, 123, 200)])
  }
  
  func testDidChangeImpressions() {
    clock!.advance(to: 123)
    
    impressionLogger!.collectionViewWillDisplayContent(atIndex: IndexPath(index: 0))
    impressionLogger!.collectionViewWillDisplayContent(atIndex: IndexPath(index: 1))
    impressionLogger!.collectionViewWillDisplayContent(atIndex: IndexPath(index: 2))
    impressionLogger!.collectionViewWillDisplayContent(atIndex: IndexPath(index: 3))
    assertContentsEqual(delegate!.startImpressions,
                        [impression(0, 123), impression(1, 123),
                         impression(2, 123), impression(3, 123)])

    delegate!.clear()
    let visibleItems = [IndexPath(index: 2), IndexPath(index: 3),
                        IndexPath(index: 4), IndexPath(index: 5)]
    clock!.now = 200
    
    impressionLogger!.collectionViewDidChangeContent(atIndexes: visibleItems)
    assertContentsEqual(delegate!.startImpressions,
                        [impression(4, 200), impression(5, 200)])
    assertContentsEqual(delegate!.endImpressions,
                        [impression(0, 123, 200), impression(1, 123, 200)])
  }
  
  func testDidHideAllImpressions() {
    clock!.advance(to: 123)
    
    impressionLogger!.collectionViewWillDisplayContent(atIndex: IndexPath(index: 0))
    impressionLogger!.collectionViewWillDisplayContent(atIndex: IndexPath(index: 1))
    impressionLogger!.collectionViewWillDisplayContent(atIndex: IndexPath(index: 2))
    impressionLogger!.collectionViewWillDisplayContent(atIndex: IndexPath(index: 3))
    assertContentsEqual(delegate!.startImpressions,
                        [impression(0, 123), impression(1, 123),
                         impression(2, 123), impression(3, 123)])

    delegate!.clear()
    clock!.now = 200
    
    impressionLogger!.collectionViewDidHideAllContent()
    assertContentsEqual(delegate!.startImpressions, [])
    assertContentsEqual(delegate!.endImpressions,
                        [impression(0, 123, 200), impression(1, 123, 200),
                         impression(2, 123, 200), impression(3, 123, 200)])
  }
  
  func testSingleSectionArrayDataSource() {
    let array = [Item(itemID: "id0"), Item(itemID: "id1"), Item(itemID: "id2")]
    impressionLogger = ImpressionLogger(singleSectionArray: array,
                                        metricsLogger: metricsLogger!,
                                        clock: clock!)
    
    clock!.advance(to: 123)
    impressionLogger!.collectionViewWillDisplayContent(atIndex: IndexPath(index: 0))
    impressionLogger!.collectionViewWillDisplayContent(atIndex: IndexPath(index: 1))

    XCTAssertEqual(2, metricsLogger!.logMessages.count)
    let impression0 = metricsLogger!.logMessages[0] as! Event_Impression
    XCTAssertEqual(idMap!.impressionID(clientID: "id0"), impression0.impressionID)
    let impression1 = metricsLogger!.logMessages[1] as! Event_Impression
    XCTAssertEqual(idMap!.impressionID(clientID: "id1"), impression1.impressionID)
  }
  
  func testMultiSectionArrayDataSource() {
    let array = [[Item(itemID: "id0")], [Item(itemID: "id1"), Item(itemID: "id2")]]
    impressionLogger = ImpressionLogger(multiSectionArray: array,
                                        metricsLogger: metricsLogger!,
                                        clock: clock!)
    
    clock!.advance(to: 123)
    impressionLogger!.collectionViewWillDisplayContent(atIndex: IndexPath(indexes: [0, 0]))
    impressionLogger!.collectionViewWillDisplayContent(atIndex: IndexPath(indexes: [1, 0]))

    XCTAssertEqual(2, metricsLogger!.logMessages.count)
    let impression0 = metricsLogger!.logMessages[0] as! Event_Impression
    XCTAssertEqual(idMap!.impressionID(clientID: "id0"), impression0.impressionID)
    let impression1 = metricsLogger!.logMessages[1] as! Event_Impression
    XCTAssertEqual(idMap!.impressionID(clientID: "id1"), impression1.impressionID)
  }
  
  static var allTests = [
    ("testStartImpressions", testStartImpressions),
    ("testEndImpressions", testEndImpressions),
    ("testDidChangeImpressions", testDidChangeImpressions),
    ("testDidHideAllImpressions", testDidHideAllImpressions),
    ("testSingleSectionArrayDataSource", testSingleSectionArrayDataSource),
    ("testMultiSectionArrayDataSource", testMultiSectionArrayDataSource),
  ]
}

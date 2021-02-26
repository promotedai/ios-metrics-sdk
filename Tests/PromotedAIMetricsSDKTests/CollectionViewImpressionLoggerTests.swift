import Foundation
import XCTest

@testable import PromotedAIMetricsSDK

final class CollectionViewImpressionLoggerTests: XCTestCase {
  class FakeDataSource: CollectionViewImpressionLoggerDataSource {
    var indexPathsForVisibleItems: [IndexPath]
    init(items: [IndexPath] = []) { indexPathsForVisibleItems = items }
  }
  
  class Delegate: CollectionViewImpressionLoggerDelegate {
    var startImpressions: [CollectionViewCellImpression]
    var endImpressions: [CollectionViewCellImpression]
    init() {
      startImpressions = []
      endImpressions = []
    }
    func clear() {
      startImpressions.removeAll()
      endImpressions.removeAll()
    }
    func impressionLogger(_ impressionLogger: CollectionViewImpressionLogger,
                          didStartImpressions impressions: [CollectionViewCellImpression]) {
      startImpressions.append(contentsOf: impressions)
    }
    
    func impressionLogger(_ impressionLogger: CollectionViewImpressionLogger,
                          didEndImpressions impressions: [CollectionViewCellImpression]) {
      endImpressions.append(contentsOf: impressions)
    }
  }
  
  private func impression(_ item: IndexPath.Element,
                          _ startTime: TimeInterval,
                          _ endTime: TimeInterval = -1.0) -> CollectionViewCellImpression {
    let path = IndexPath(index: item)
    return CollectionViewCellImpression(path: path, startTime: startTime, endTime: endTime)
  }

  /** Asserts that list contents are equal regardless of order. */
  func assertContentsEqual(_ a: [CollectionViewCellImpression],
                           _ b: [CollectionViewCellImpression]) {
    XCTAssertEqual(Set(a), Set(b))
  }
  
  func testStartImpressions() {
    let dataSource = FakeDataSource()
    let delegate = Delegate()
    let clock = FakeClock(now: 123)
    let impressionLogger = CollectionViewImpressionLogger(
        dataSource: dataSource, delegate: delegate, clock: clock)
    
    impressionLogger.collectionViewWillDisplay(item: IndexPath(index: 0))
    assertContentsEqual(delegate.startImpressions, [impression(0, 123)])
    
    delegate.clear()
    clock.now = 500
    impressionLogger.collectionViewWillDisplay(item: IndexPath(index: 0))
    clock.now = 501
    impressionLogger.collectionViewWillDisplay(item: IndexPath(index: 1))
    clock.now = 502
    impressionLogger.collectionViewWillDisplay(item: IndexPath(index: 2))
    assertContentsEqual(delegate.startImpressions,
                        [impression(0, 500), impression(1, 501), impression(2, 502)])
  }
  
  func testEndImpressions() {
    let dataSource = FakeDataSource()
    let delegate = Delegate()
    let clock = FakeClock(now: 123)
    let impressionLogger = CollectionViewImpressionLogger(
        dataSource: dataSource, delegate: delegate, clock: clock)
    
    impressionLogger.collectionViewWillDisplay(item: IndexPath(index: 0))
    clock.now = 200
    impressionLogger.collectionViewDidHide(item: IndexPath(index: 0))
    assertContentsEqual(delegate.endImpressions, [impression(0, 123, 200)])
  }
  
  func testDidChangeImpressions() {
    let dataSource = FakeDataSource()
    let delegate = Delegate()
    let clock = FakeClock(now: 123)
    let impressionLogger = CollectionViewImpressionLogger(
        dataSource: dataSource, delegate: delegate, clock: clock)
    
    impressionLogger.collectionViewWillDisplay(item: IndexPath(index: 0))
    impressionLogger.collectionViewWillDisplay(item: IndexPath(index: 1))
    impressionLogger.collectionViewWillDisplay(item: IndexPath(index: 2))
    impressionLogger.collectionViewWillDisplay(item: IndexPath(index: 3))
    assertContentsEqual(delegate.startImpressions,
                        [impression(0, 123), impression(1, 123),
                         impression(2, 123), impression(3, 123)])

    delegate.clear()
    dataSource.indexPathsForVisibleItems = [IndexPath(index: 2), IndexPath(index: 3),
                                            IndexPath(index: 4), IndexPath(index: 5)]
    clock.now = 200
    
    impressionLogger.collectionViewDidReloadAllItems()
    assertContentsEqual(delegate.startImpressions,
                        [impression(4, 200), impression(5, 200)])
    assertContentsEqual(delegate.endImpressions,
                        [impression(0, 123, 200), impression(1, 123, 200)])
  }
  
  func testDidHideAllImpressions() {
    let dataSource = FakeDataSource()
    let delegate = Delegate()
    let clock = FakeClock(now: 123)
    let impressionLogger = CollectionViewImpressionLogger(
        dataSource: dataSource, delegate: delegate, clock: clock)
    
    impressionLogger.collectionViewWillDisplay(item: IndexPath(index: 0))
    impressionLogger.collectionViewWillDisplay(item: IndexPath(index: 1))
    impressionLogger.collectionViewWillDisplay(item: IndexPath(index: 2))
    impressionLogger.collectionViewWillDisplay(item: IndexPath(index: 3))
    assertContentsEqual(delegate.startImpressions,
                        [impression(0, 123), impression(1, 123),
                         impression(2, 123), impression(3, 123)])

    delegate.clear()
    clock.now = 200
    
    impressionLogger.collectionViewDidHideAllItems()
    assertContentsEqual(delegate.startImpressions, [])
    assertContentsEqual(delegate.endImpressions,
                        [impression(0, 123, 200), impression(1, 123, 200),
                         impression(2, 123, 200), impression(3, 123, 200)])
  }

  static var allTests = [
    ("testStartImpressions", testStartImpressions),
    ("testEndImpressions", testEndImpressions),
    ("testDidChangeImpressions", testDidChangeImpressions),
    ("testDidHideAllImpressions", testDidHideAllImpressions),
  ]
}
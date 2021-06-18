import Foundation
import XCTest

@testable import PromotedCore
@testable import PromotedCoreTestHelpers

final class ImpressionTrackerTests: ModuleTestCase {

  typealias Impression = ImpressionTracker.Impression

  class Delegate: ImpressionTrackerDelegate {
    var startImpressions: [Impression]
    var endImpressions: [Impression]
    init() {
      startImpressions = []
      endImpressions = []
    }
    func clear() {
      startImpressions.removeAll()
      endImpressions.removeAll()
    }
    func impressionTracker(_ impressionTracker: ImpressionTracker,
                          didStartImpressions impressions: [Impression]) {
      startImpressions.append(contentsOf: impressions)
    }
    
    func impressionTracker(_ impressionTracker: ImpressionTracker,
                          didEndImpressions impressions: [Impression]) {
      endImpressions.append(contentsOf: impressions)
    }
  }
  
  private func content(_ contentID: String) -> Content {
    return Content(contentID: contentID)
  }
  
  private func impression(_ contentID: String,
                          _ startTime: TimeInterval,
                          _ endTime: TimeInterval? = nil) -> Impression {
    let content = Content(contentID: contentID)
    return ImpressionTracker.Impression(content: content, startTime: startTime, endTime: endTime)
  }

  /** Asserts that list contents are equal regardless of order. */
  func assertContentsEqual(_ a: [Impression], _ b: [Impression]) {
    XCTAssertEqual(Set(a), Set(b))
  }

  private var metricsLogger: MetricsLogger!
  private var impressionTracker: ImpressionTracker!
  private var delegate: Delegate!

  override func setUp() {
    super.setUp()
    metricsLogger = MetricsLogger(deps: module)
    metricsLogger.startSessionAndLogUser(userID: "foo")
    impressionTracker = ImpressionTracker(metricsLogger: metricsLogger, deps: module)
    delegate = Delegate()
    impressionTracker.delegate = delegate
  }

  func testStartImpressions() {
    clock.advance(to: 123)
    
    impressionTracker.collectionViewWillDisplay(content: content("jeff"))
    assertContentsEqual(delegate.startImpressions, [impression("jeff", 123)])
    
    delegate.clear()
    clock.now = 500
    impressionTracker.collectionViewWillDisplay(content: content("britta"))
    clock.now = 501
    impressionTracker.collectionViewWillDisplay(content: content("troy"))
    clock.now = 502
    impressionTracker.collectionViewWillDisplay(content: content("abed"))
    assertContentsEqual(delegate.startImpressions,
                        [impression("britta", 500),
                         impression("troy", 501),
                         impression("abed", 502)])
  }
  
  func testEndImpressions() {
    clock.advance(to: 123)
    
    impressionTracker.collectionViewWillDisplay(content: content("annie"))
    clock.now = 200
    impressionTracker.collectionViewDidHide(content: content("annie"))
    assertContentsEqual(delegate.endImpressions, [impression("annie", 123, 200)])
  }
  
  func testDidChangeImpressions() {
    clock.advance(to: 123)
    
    impressionTracker.collectionViewWillDisplay(content: content("shirley"))
    impressionTracker.collectionViewWillDisplay(content: content("pierce"))
    impressionTracker.collectionViewWillDisplay(content: content("ben"))
    impressionTracker.collectionViewWillDisplay(content: content("craig"))
    assertContentsEqual(delegate.startImpressions,
                        [impression("shirley", 123),
                         impression("pierce", 123),
                         impression("ben", 123),
                         impression("craig", 123)])

    delegate.clear()
    let visibleContent = [content("shirley"),
                          content("craig"),
                          content("troy"),
                          content("abed")]
    clock.now = 200
    
    impressionTracker.collectionViewDidChangeVisibleContent(visibleContent)
    assertContentsEqual(delegate.startImpressions,
                        [impression("troy", 200), impression("abed", 200)])
    assertContentsEqual(delegate.endImpressions,
                        [impression("pierce", 123, 200), impression("ben", 123, 200)])
  }
  
  func testDidHideAllImpressions() {
    clock.advance(to: 123)
    
    impressionTracker.collectionViewWillDisplay(content: content("jeff"))
    impressionTracker.collectionViewWillDisplay(content: content("britta"))
    impressionTracker.collectionViewWillDisplay(content: content("annie"))
    impressionTracker.collectionViewWillDisplay(content: content("troy"))
    assertContentsEqual(delegate.startImpressions,
                        [impression("jeff", 123),
                         impression("britta", 123),
                         impression("annie", 123),
                         impression("troy", 123)])

    delegate.clear()
    clock.now = 200
    
    impressionTracker.collectionViewDidHideAllContent()
    assertContentsEqual(delegate.startImpressions, [])
    assertContentsEqual(delegate.endImpressions,
                        [impression("jeff", 123, 200),
                         impression("britta", 123, 200),
                         impression("annie", 123, 200),
                         impression("troy", 123, 200)])
  }
}

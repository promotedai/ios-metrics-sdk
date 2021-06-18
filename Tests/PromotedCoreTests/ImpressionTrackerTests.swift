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
                          _ endTime: TimeInterval? = nil,
                          _ sourceType: ImpressionSourceType = .unknown) -> Impression {
    let content = Content(contentID: contentID)
    return ImpressionTracker.Impression(content: content, startTime: startTime, endTime: endTime, sourceType: sourceType)
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

  private func assertEventsLogged(eventJSONArray: [String]) {
    metricsLogger.flush()
    let message = connection.messages.last?.message
    XCTAssertTrue(message is Event_LogRequest)
    let eventJSONJoined = eventJSONArray.joined(separator: ",")
    let expectedLogRequestJSON = """
    {
      "user_info": {
        "user_id": "foo",
        "log_user_id": "fake-log-user-id"
      },
      "impression": [
        \(eventJSONJoined)
      ]
    }
    """
    XCTAssertEqual(try Event_LogRequest(jsonString: expectedLogRequestJSON),
                   message as! Event_LogRequest)
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

  func testStartImpressionsLoggedEvents() {
    impressionTracker = ImpressionTracker(metricsLogger: metricsLogger, deps: module)
      .with(sourceType: .delivery)
    clock.advance(to: 123)
    impressionTracker.collectionViewWillDisplay(content: content("jeff"))
    clock.now = 500
    impressionTracker.collectionViewWillDisplay(content: content("britta"))
    clock.now = 501
    impressionTracker.collectionViewWillDisplay(content: content("troy"))
    clock.now = 502
    impressionTracker.collectionViewWillDisplay(content: content("abed"))
    let expectedEventsJSON: [String] = [
      """
      {
        "timing": {
          "client_log_timestamp": 123000
        },
        "impression_id": "fake-impression-id",
        "session_id": "fake-session-id",
        "content_id": "jeff",
        "source_type": "DELIVERY"
      }
      """,
      """
      {
        "timing": {
          "client_log_timestamp": 500000
        },
        "impression_id": "fake-impression-id",
        "session_id": "fake-session-id",
        "content_id": "britta",
        "source_type": "DELIVERY"
      }
      """,
      """
      {
        "timing": {
          "client_log_timestamp": 501000
        },
        "impression_id": "fake-impression-id",
        "session_id": "fake-session-id",
        "content_id": "troy",
        "source_type": "DELIVERY"
      }
      """,
      """
      {
        "timing": {
          "client_log_timestamp": 502000
        },
        "impression_id": "fake-impression-id",
        "session_id": "fake-session-id",
        "content_id": "abed",
        "source_type": "DELIVERY"
      }
      """
    ]
    assertEventsLogged(eventJSONArray: expectedEventsJSON)
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

import Foundation
import SwiftProtobuf
import XCTest

@testable import PromotedCore
@testable import PromotedCoreTestHelpers

final class MetricsLoggerTests: ModuleTestCase {

  private class FakeScreenViewController: UIViewController {}

  private var metricsLogger: MetricsLogger!

  override func setUp() {
    super.setUp()
    module.clientConfig.metricsLoggingURL = "http://fake.promoted.ai/metrics"
    clock.advance(to: 123)
    store.userID = "foobar"
    store.logUserID = "fake-log-user-id"
    metricsLogger = MetricsLogger(deps: module)
  }

  private func assertLoggerAndStoreInSync() {
    XCTAssertEqual(store.userID, metricsLogger.userID.stringValue)
    XCTAssertEqual(store.logUserID, metricsLogger.logUserID)
  }

  private func assertEmptyList<T>(_ list: [T]) {
    XCTAssertEqual(0, list.count, "Not empty: \(list)")
  }

  @discardableResult
  private func assertSingletonList<T>(_ list: [T]) -> T {
    XCTAssertEqual(1, list.count, "Not singleton: \(list)")
    return list.last!
  }

  private func assertSingletonList<T, U>(
    _ list: [T],
    as: U.Type
  ) -> U {
    return assertSingletonList(list) as! U
  }

  func testStartSession() {
    store.userID = nil
    store.logUserID = nil
    idMap.incrementCounts = true
    metricsLogger.startSessionForTesting(userID: "foobar")
    XCTAssertEqual("foobar", store.userID)
    XCTAssertNotNil(store.logUserID)
    assertLoggerAndStoreInSync()
  }

  func testStartSessionMultiple() {
    store.userID = nil
    store.logUserID = nil
    idMap.incrementCounts = true
    metricsLogger.startSessionForTesting(userID: "foobar")
    XCTAssertEqual("foobar", store.userID)
    XCTAssertNotNil(store.logUserID)
    assertLoggerAndStoreInSync()
    
    let previousLogUserID = store.logUserID
    metricsLogger.startSessionForTesting(userID: "foobar")
    XCTAssertEqual("foobar", store.userID)
    XCTAssertEqual(previousLogUserID, store.logUserID)
    assertLoggerAndStoreInSync()
    
    metricsLogger.startSessionForTesting(userID: "foobarbaz")
    XCTAssertEqual("foobarbaz", store.userID)
    XCTAssertNotNil(store.logUserID)
    XCTAssertNotEqual(previousLogUserID, store.logUserID)
    assertLoggerAndStoreInSync()
  }

  func testStartSessionSignedOut() {
    store.userID = nil
    store.logUserID = nil
    idMap.incrementCounts = true
    metricsLogger.startSessionSignedOutForTesting()
    XCTAssertNil(store.userID)
    XCTAssertNotNil(store.logUserID)
    assertLoggerAndStoreInSync()
  }

  func testStartSessionSignInThenSignOut() {
    store.userID = nil
    store.logUserID = nil
    idMap.incrementCounts = true
    metricsLogger.startSessionForTesting(userID: "foobar")
    XCTAssertEqual("foobar", store.userID)
    XCTAssertNotNil(store.logUserID)
    assertLoggerAndStoreInSync()

    let previousLogUserID = store.logUserID
    metricsLogger.startSessionSignedOutForTesting()
    XCTAssertNil(store.userID)
    XCTAssertNotNil(store.logUserID)
    XCTAssertNotEqual(previousLogUserID, store.logUserID)
    assertLoggerAndStoreInSync()
  }

  func testStartSessionSignOutThenSignIn() {
    store.userID = nil
    store.logUserID = nil
    idMap.incrementCounts = true
    metricsLogger.startSessionSignedOutForTesting()
    XCTAssertNil(store.userID)
    XCTAssertNotNil(store.logUserID)
    assertLoggerAndStoreInSync()

    let previousLogUserID = store.logUserID
    metricsLogger.startSessionForTesting(userID: "foobar")
    XCTAssertEqual("foobar", store.userID)
    XCTAssertNotNil(store.logUserID)
    XCTAssertNotEqual(previousLogUserID, store.logUserID)
    assertLoggerAndStoreInSync()
  }

  func testReadIDsBeforeStartSessionWithUserID() {
    store.userID = "foobar"
    store.logUserID = "fake-initial-id"
    idMap.incrementCounts = true
    let initialLogUserID = metricsLogger.currentOrPendingLogUserID
    XCTAssertEqual("fake-initial-id", initialLogUserID)
    let initialSessionID = metricsLogger.currentOrPendingSessionID
    XCTAssertEqual("fake-session-id-1", initialSessionID)

    metricsLogger.startSessionForTesting(userID: "foobar")
    XCTAssertEqual(initialLogUserID, metricsLogger.logUserID)
    XCTAssertEqual(initialSessionID, metricsLogger.sessionID)

    metricsLogger.startSessionForTesting(userID: "batman")
    XCTAssertNotEqual(initialLogUserID, metricsLogger.logUserID)
    XCTAssertNotEqual(initialSessionID, metricsLogger.sessionID)
  }

  func testReadIDsBeforeStartSessionSignedOut() {
    store.userID = "foobar"
    store.logUserID = "fake-initial-id"
    idMap.incrementCounts = true
    let initialLogUserID = metricsLogger.currentOrPendingLogUserID
    XCTAssertEqual("fake-initial-id", initialLogUserID)
    let initialSessionID = metricsLogger.currentOrPendingSessionID
    XCTAssertEqual("fake-session-id-1", initialSessionID)

    metricsLogger.startSessionSignedOutForTesting()
    XCTAssertEqual(initialLogUserID, metricsLogger.logUserID)
    XCTAssertEqual(initialSessionID, metricsLogger.sessionID)

    metricsLogger.startSessionForTesting(userID: "batman")
    XCTAssertNotEqual(initialLogUserID, metricsLogger.logUserID)
    XCTAssertNotEqual(initialSessionID, metricsLogger.sessionID)
  }
  
  func testReadIDsBeforeStartSessionSignedOutNoPreviousLogUserID() {
    store.userID = nil
    store.logUserID = nil
    idMap.incrementCounts = true
    // This should generate a new, non-nil logUserID.
    let initialLogUserID = metricsLogger.currentOrPendingLogUserID
    XCTAssertEqual("fake-log-user-id-1", initialLogUserID)
    let initialSessionID = metricsLogger.currentOrPendingSessionID
    XCTAssertEqual("fake-session-id-1", initialSessionID)

    metricsLogger.startSessionSignedOutForTesting()
    XCTAssertEqual(initialLogUserID, metricsLogger.logUserID)
    XCTAssertEqual(initialSessionID, metricsLogger.sessionID)

    metricsLogger.startSessionForTesting(userID: "batman")
    XCTAssertNotEqual(initialLogUserID, metricsLogger.logUserID)
    XCTAssertNotEqual(initialSessionID, metricsLogger.sessionID)
  }
  
  func testReadIDsBeforeStartSessionSignedOutStaySignedOut() {
    store.userID = nil
    store.logUserID = nil
    idMap.incrementCounts = true
    // This should generate a new, non-nil logUserID.
    let initialLogUserID = metricsLogger.currentOrPendingLogUserID
    XCTAssertEqual("fake-log-user-id-1", initialLogUserID)
    let initialSessionID = metricsLogger.currentOrPendingSessionID
    XCTAssertEqual("fake-session-id-1", initialSessionID)

    metricsLogger.startSessionSignedOutForTesting()
    XCTAssertEqual(initialLogUserID, metricsLogger.logUserID)
    XCTAssertEqual(initialSessionID, metricsLogger.sessionID)

    metricsLogger.startSessionSignedOutForTesting()
    XCTAssertNotEqual(initialLogUserID, metricsLogger.logUserID)
    XCTAssertNotEqual(initialSessionID, metricsLogger.sessionID)
  }

  func testFlush() {
    let flushInterval = config.loggingFlushInterval
    metricsLogger.startSessionForTesting(userID: "foobar")
    let e = Event_Action()

    clock.advance(to: 0.0)
    metricsLogger.log(message: e)
    assertSingletonList(clock.scheduledTimers)
    XCTAssertEqual(flushInterval, clock.scheduledTimers[0].timeInterval)
    assertSingletonList(metricsLogger.logMessagesForTesting)
    assertEmptyList(connection.messages)

    clock.advance(to: 5.0)
    metricsLogger.log(message: e)
    assertSingletonList(clock.scheduledTimers)
    XCTAssertEqual(2, metricsLogger.logMessagesForTesting.count)
    assertEmptyList(connection.messages)

    clock.advance(to: flushInterval + 10)
    assertEmptyList(clock.scheduledTimers)
    assertEmptyList(metricsLogger.logMessagesForTesting)

    let args = assertSingletonList(connection.messages)
    guard let logRequest = args.message as? Event_LogRequest else {
      XCTFail("Message sent to connection was not a LogRequest")
      return
    }
    XCTAssertNotEqual("", logRequest.userInfo.logUserID)

    connection.messages.removeAll()
    metricsLogger.log(message: e)
    let timer = assertSingletonList(clock.scheduledTimers)
    XCTAssertEqual(flushInterval, timer.timeInterval)
    assertSingletonList(metricsLogger.logMessagesForTesting)
    assertEmptyList(connection.messages)
  }

  func testFlushNoLogUserIDs() {
    metricsLogger = MetricsLogger(deps: module)

    let flushInterval = config.loggingFlushInterval

    let e = Event_Action()
    clock.advance(to: 0.0)
    metricsLogger.log(message: e)

    clock.advance(to: flushInterval + 10)
    let args = assertSingletonList(connection.messages)
    guard let logRequest = args.message as? Event_LogRequest else {
      XCTFail("Message sent to connection was not a LogRequest")
      return
    }
    XCTAssertEqual("", logRequest.userInfo.logUserID)
  }

  func testProperties() {
    metricsLogger.startSessionForTesting(userID: "foobar")
    var properties = Event_Impression()
    properties.impressionID = "foobar"
    metricsLogger.logUserForTesting(properties: properties)
    let user = assertSingletonList(
      metricsLogger.logMessagesForTesting,
      as: Event_User.self
    )
    let propertiesData = user.properties.structBytes
    do {
      let deserializedProps = try Event_Impression(
        serializedData: propertiesData
      )
      XCTAssertEqual("foobar", deserializedProps.impressionID)
    } catch {
      XCTFail("Exception when deserializing payload")
    }
  }

  func testLogUser() {
    metricsLogger.startSessionForTesting(userID: "foo")
    metricsLogger.logUserForTesting()
    let user = assertSingletonList(
      metricsLogger.logMessagesForTesting,
      as: Event_User.self
    )
    let expectedJSON = """
    {
      "user_info": {
        "user_id": "foo",
        "log_user_id": "fake-log-user-id"
      },
      "timing": {
        "client_log_timestamp": 123000
      }
    }
    """
    XCTAssertEqual(
      try Event_User(jsonString: expectedJSON),
      user
    )
  }

  func testLogUserIDProvenances() {
    module.clientConfig.eventsIncludeIDProvenances = true
    metricsLogger = MetricsLogger(deps: module)
    metricsLogger.startSessionForTesting(userID: "foo")
    metricsLogger.logUserForTesting()
    let user = assertSingletonList(
      metricsLogger.logMessagesForTesting,
      as: Event_User.self
    )
    let expectedJSON = """
    {
      "user_info": {
        "user_id": "foo",
        "log_user_id": "fake-log-user-id"
      },
      "timing": {
        "client_log_timestamp": 123000
      },
      "id_provenances": {
        "user_id_provenance": "PLATFORM_SPECIFIED",
        "log_user_id_provenance": "AUTOGENERATED",
        "session_id_provenance": "AUTOGENERATED",
        "view_id_provenance": "NULL",
        "impression_id_provenance": "NULL",
        "action_id_provenance": "NULL",
        "content_id_provenance": "NULL",
        "insertion_id_provenance": "NULL",
        "request_id_provenance": "NULL",
        "auto_view_id_provenance": "NULL"
      }
    }
    """
    XCTAssertEqual(
      try Event_User(jsonString: expectedJSON),
      user
    )
  }

  func testLogImpressionInsertionID() {
    metricsLogger.startSessionForTesting(userID: "foo")
    let item = Content(contentID: "foobar", insertionID: "insertion!")
    metricsLogger.logImpression(content: item, autoViewState: .fake)
    let impression = assertSingletonList(
      metricsLogger.logMessagesForTesting,
      as: Event_Impression.self
    )
    let expectedJSON = """
    {
      "timing": {
        "client_log_timestamp": 123000
      },
      "impression_id": "fake-impression-id",
      "insertion_id": "insertion!",
      "content_id": "foobar",
      "session_id": "fake-session-id",
      "auto_view_id": "fake-auto-view-id"
    }
    """
    XCTAssertEqual(
      try Event_Impression(jsonString: expectedJSON),
      impression
    )
  }

  func testLogImpressionNoInsertionID() {
    metricsLogger.startSessionForTesting(userID: "foo")
    let item = Content(contentID: "foobar")
    metricsLogger.logImpression(content: item, autoViewState: .fake)
    let impression = assertSingletonList(
      metricsLogger.logMessagesForTesting,
      as: Event_Impression.self
    )
    let expectedJSON = """
    {
      "timing": {
        "client_log_timestamp": 123000
      },
      "impression_id": "fake-impression-id",
      "content_id": "foobar",
      "session_id": "fake-session-id",
      "auto_view_id": "fake-auto-view-id"
    }
    """
    XCTAssertEqual(
      try Event_Impression(jsonString: expectedJSON),
      impression
    )
  }

  func testLogImpressionNoLogUserSessionViewIDs() {
    let item = Content(contentID: "foobar", insertionID: "insertion!")
    metricsLogger.logImpression(content: item)
    let impression = assertSingletonList(
      metricsLogger.logMessagesForTesting,
      as: Event_Impression.self
    )
    let expectedJSON = """
    {
      "timing": {
        "client_log_timestamp": 123000
      },
      "impression_id": "fake-impression-id",
      "insertion_id": "insertion!",
      "content_id": "foobar"
    }
    """
    XCTAssertEqual(
      try Event_Impression(jsonString: expectedJSON),
      impression
    )
  }

  func testLogImpressionExternalLogUserID() {
    let item = Content(contentID: "foobar", insertionID: "insertion!")
    metricsLogger.logUserID = "batman"
    metricsLogger.logImpression(content: item)
    metricsLogger.flush()
    let message = assertSingletonList(connection.messages).message
    XCTAssertTrue(message is Event_LogRequest)
    let expectedJSON = """
    {
      "client_info": {
        "client_type": 2,
        "traffic_type": 1
      },
      "user_info": {
        "log_user_id": "batman"
      },
      \(FakeDeviceInfo.json),
      "impression": [
        {
          "timing": {
            "client_log_timestamp": 123000
          },
          "impression_id": "fake-impression-id",
          "insertion_id": "insertion!",
          "content_id": "foobar"
        }
      ]
    }
    """
    XCTAssertEqual(
      try Event_LogRequest(jsonString: expectedJSON),
      message as! Event_LogRequest
    )
  }

  func testLogImpressionMultipleExternalIDs() {
    let item = Content(contentID: "foobar", insertionID: "insertion!")
    metricsLogger.logUserID = "batman"
    metricsLogger.sessionID = "gotham"
    metricsLogger.viewID = "joker"
    metricsLogger.logImpression(content: item, autoViewState: .fake)
    metricsLogger.flush()
    let message = connection.messages.last?.message
    XCTAssertTrue(message is Event_LogRequest)
    let expectedJSON = """
    {
      "client_info": {
        "client_type": 2,
        "traffic_type": 1
      },
      "user_info": {
        "log_user_id": "batman"
      },
      \(FakeDeviceInfo.json),
      "impression": [
        {
          "timing": {
            "client_log_timestamp": 123000
          },
          "impression_id": "fake-impression-id",
          "insertion_id": "insertion!",
          "content_id": "foobar",
          "session_id": "gotham",
          "view_id": "joker",
          "auto_view_id": "fake-auto-view-id"
        }
      ]
    }
    """
    XCTAssertEqual(
      try Event_LogRequest(jsonString: expectedJSON),
      message as! Event_LogRequest
    )
  }

  func testLogImpressionIDProvenances() {
    module.clientConfig.eventsIncludeIDProvenances = true
    metricsLogger = MetricsLogger(deps: module)
    metricsLogger.startSessionForTesting(userID: "foo")
    let item = Content(contentID: "foobar", insertionID: "insertion!")
    metricsLogger.logImpression(content: item, autoViewState: .fake)
    let impression = assertSingletonList(
      metricsLogger.logMessagesForTesting,
      as: Event_Impression.self
    )
    let expectedJSON = """
    {
      "timing": {
        "client_log_timestamp": 123000
      },
      "impression_id": "fake-impression-id",
      "insertion_id": "insertion!",
      "content_id": "foobar",
      "session_id": "fake-session-id",
      "auto_view_id": "fake-auto-view-id",
      "id_provenances": {
        "user_id_provenance": "PLATFORM_SPECIFIED",
        "log_user_id_provenance": "AUTOGENERATED",
        "session_id_provenance": "AUTOGENERATED",
        "view_id_provenance": "NULL",
        "impression_id_provenance": "AUTOGENERATED",
        "action_id_provenance": "NULL",
        "content_id_provenance": "PLATFORM_SPECIFIED",
        "insertion_id_provenance": "AUTOGENERATED",
        "request_id_provenance": "NULL",
        "auto_view_id_provenance": "AUTOGENERATED"
      }
    }
    """
    XCTAssertEqual(
      try Event_Impression(jsonString: expectedJSON),
      impression
    )
  }

  func testLogImpressionClientPosition() {
    module.clientConfig.eventsIncludeClientPositions = true
    metricsLogger = MetricsLogger(deps: module)
    metricsLogger.startSessionForTesting(userID: "foo")
    let item = Content(contentID: "foobar", insertionID: "insertion!")
    let collectionInteraction = CollectionInteraction(indexPath: [5, 6])
    metricsLogger.logImpression(
      content: item,
      autoViewState: .fake,
      collectionInteraction: collectionInteraction
    )
    let impression = assertSingletonList(
      metricsLogger.logMessagesForTesting,
      as: Event_Impression.self
    )
    let expectedJSON = """
    {
      "timing": {
        "client_log_timestamp": 123000
      },
      "impression_id": "fake-impression-id",
      "insertion_id": "insertion!",
      "content_id": "foobar",
      "session_id": "fake-session-id",
      "auto_view_id": "fake-auto-view-id",
      "client_position": {
        "index": [5, 6]
      }
    }
    """
    XCTAssertEqual(
      try Event_Impression(jsonString: expectedJSON),
      impression
    )
  }

  func testLogNavigateAction() {
    metricsLogger.startSessionForTesting(userID: "foo")
    let viewController = FakeScreenViewController()
    let item = Content(contentID: "foobar")
    metricsLogger.logNavigateAction(
      content: item,
      viewController: viewController,
      autoViewState: .fake
    )
    let action = assertSingletonList(
      metricsLogger.logMessagesForTesting,
      as: Event_Action.self
    )
    let expectedJSON = """
    {
      "timing": {
        "client_log_timestamp": 123000
      },
      "action_id": "fake-action-id",
      "session_id": "fake-session-id",
      "auto_view_id": "fake-auto-view-id",
      "content_id": "foobar",
      "name": "FakeScreen",
      "action_type": "NAVIGATE",
      "element_id": "FakeScreen",
      "navigate_action": {
      }
    }
    """
    XCTAssertEqual(
      try Event_Action(jsonString: expectedJSON),
      action
    )
  }
  
  func testLogAddToCartAction() {
    metricsLogger.startSessionForTesting(userID: "foo")
    let item = Content(contentID: "foobar")
    metricsLogger.logAction(
      type: .addToCart,
      content: item,
      autoViewState: .fake
    )
    let action = assertSingletonList(
      metricsLogger.logMessagesForTesting,
      as: Event_Action.self
    )
    let expectedJSON = """
    {
      "timing": {
        "client_log_timestamp": 123000
      },
      "action_id": "fake-action-id",
      "session_id": "fake-session-id",
      "auto_view_id": "fake-auto-view-id",
      "content_id": "foobar",
      "name": "add-to-cart",
      "action_type": "ADD_TO_CART",
      "element_id": "add-to-cart"
    }
    """
    XCTAssertEqual(
      try Event_Action(jsonString: expectedJSON),
      action
    )
  }
  
  func testLogRemoveFromCartAction() {
    metricsLogger.startSessionForTesting(userID: "foo")
    let item = Content(contentID: "foobar")
    metricsLogger.logAction(
      type: .removeFromCart,
      content: item,
      autoViewState: .fake
    )
    let action = assertSingletonList(
      metricsLogger.logMessagesForTesting,
      as: Event_Action.self
    )
    let expectedJSON = """
    {
      "timing": {
        "client_log_timestamp": 123000
      },
      "action_id": "fake-action-id",
      "session_id": "fake-session-id",
      "auto_view_id": "fake-auto-view-id",
      "content_id": "foobar",
      "name": "remove-from-cart",
      "action_type": "REMOVE_FROM_CART",
      "element_id": "remove-from-cart"
    }
    """
    XCTAssertEqual(
      try Event_Action(jsonString: expectedJSON),
      action
    )
  }
  
  func testLogCheckoutAction() {
    metricsLogger.startSessionForTesting(userID: "foo")
    metricsLogger.logAction(
      type: .checkout,
      content: nil,
      autoViewState: .fake
    )
    let action = assertSingletonList(
      metricsLogger.logMessagesForTesting,
      as: Event_Action.self
    )
    let expectedJSON = """
    {
      "timing": {
        "client_log_timestamp": 123000
      },
      "action_id": "fake-action-id",
      "session_id": "fake-session-id",
      "auto_view_id": "fake-auto-view-id",
      "name": "checkout",
      "action_type": "CHECKOUT",
      "element_id": "checkout"
    }
    """
    XCTAssertEqual(
      try Event_Action(jsonString: expectedJSON),
      action
    )
  }
  
  func testLogPurchaseAction() {
    metricsLogger.startSessionForTesting(userID: "foo")
    let item = Content(contentID: "foobar")
    metricsLogger.logAction(
      type: .purchase,
      content: item,
      autoViewState: .fake
    )
    let action = assertSingletonList(
      metricsLogger.logMessagesForTesting,
      as: Event_Action.self
    )
    let expectedJSON = """
    {
      "timing": {
        "client_log_timestamp": 123000
      },
      "action_id": "fake-action-id",
      "session_id": "fake-session-id",
      "auto_view_id": "fake-auto-view-id",
      "content_id": "foobar",
      "name": "purchase",
      "action_type": "PURCHASE",
      "element_id": "purchase"
    }
    """
    XCTAssertEqual(
      try Event_Action(jsonString: expectedJSON),
      action
    )
  }
  
  func testLogShareAction() {
    metricsLogger.startSessionForTesting(userID: "foo")
    let item = Content(contentID: "foobar")
    metricsLogger.logAction(
      type: .share,
      content: item,
      autoViewState: .fake
    )
    let action = assertSingletonList(
      metricsLogger.logMessagesForTesting,
      as: Event_Action.self
    )
    let expectedJSON = """
    {
      "timing": {
        "client_log_timestamp": 123000
      },
      "action_id": "fake-action-id",
      "session_id": "fake-session-id",
      "auto_view_id": "fake-auto-view-id",
      "content_id": "foobar",
      "name": "share",
      "action_type": "SHARE",
      "element_id": "share"
    }
    """
    XCTAssertEqual(
      try Event_Action(jsonString: expectedJSON),
      action
    )
  }

  func testLogLikeAction() {
    metricsLogger.startSessionForTesting(userID: "foo")
    let item = Content(contentID: "foobar")
    metricsLogger.logAction(
      type: .like,
      content: item,
      autoViewState: .fake
    )
    let action = assertSingletonList(
      metricsLogger.logMessagesForTesting,
      as: Event_Action.self
    )
    let expectedJSON = """
    {
      "timing": {
        "client_log_timestamp": 123000
      },
      "action_id": "fake-action-id",
      "session_id": "fake-session-id",
      "auto_view_id": "fake-auto-view-id",
      "content_id": "foobar",
      "name": "like",
      "action_type": "LIKE",
      "element_id": "like"
    }
    """
    XCTAssertEqual(
      try Event_Action(jsonString: expectedJSON),
      action
    )
  }

  func testLogUnlikeAction() {
    metricsLogger.startSessionForTesting(userID: "foo")
    let item = Content(contentID: "foobar")
    metricsLogger.logAction(
      type: .unlike,
      content: item,
      autoViewState: .fake
    )
    let action = assertSingletonList(
      metricsLogger.logMessagesForTesting,
      as: Event_Action.self
    )
    let expectedJSON = """
    {
      "timing": {
        "client_log_timestamp": 123000
      },
      "action_id": "fake-action-id",
      "session_id": "fake-session-id",
      "auto_view_id": "fake-auto-view-id",
      "content_id": "foobar",
      "name": "unlike",
      "action_type": "UNLIKE",
      "element_id": "unlike"
    }
    """
    XCTAssertEqual(
      try Event_Action(jsonString: expectedJSON),
      action
    )
  }
  
  func testLogCommentAction() {
    metricsLogger.startSessionForTesting(userID: "foo")
    let item = Content(contentID: "foobar")
    metricsLogger.logAction(
      type: .comment,
      content: item,
      autoViewState: .fake
    )
    let action = assertSingletonList(
      metricsLogger.logMessagesForTesting,
      as: Event_Action.self
    )
    let expectedJSON = """
    {
      "timing": {
        "client_log_timestamp": 123000
      },
      "action_id": "fake-action-id",
      "session_id": "fake-session-id",
      "auto_view_id": "fake-auto-view-id",
      "content_id": "foobar",
      "name": "comment",
      "action_type": "COMMENT",
      "element_id": "comment"
    }
    """
    XCTAssertEqual(
      try Event_Action(jsonString: expectedJSON),
      action
    )
  }
  
  func testLogMakeOfferAction() {
    metricsLogger.startSessionForTesting(userID: "foo")
    let item = Content(contentID: "foobar")
    metricsLogger.logAction(
      type: .makeOffer,
      content: item,
      autoViewState: .fake
    )
    let action = assertSingletonList(
      metricsLogger.logMessagesForTesting,
      as: Event_Action.self
    )
    let expectedJSON = """
    {
      "timing": {
        "client_log_timestamp": 123000
      },
      "action_id": "fake-action-id",
      "session_id": "fake-session-id",
      "auto_view_id": "fake-auto-view-id",
      "content_id": "foobar",
      "name": "make-offer",
      "action_type": "MAKE_OFFER",
      "element_id": "make-offer"
    }
    """
    XCTAssertEqual(
      try Event_Action(jsonString: expectedJSON),
      action
    )
  }
  
  func testLogAskQuestionAction() {
    metricsLogger.startSessionForTesting(userID: "foo")
    let item = Content(contentID: "foobar")
    metricsLogger.logAction(
      type: .askQuestion,
      content: item,
      autoViewState: .fake
    )
    let action = assertSingletonList(
      metricsLogger.logMessagesForTesting,
      as: Event_Action.self
    )
    let expectedJSON = """
    {
      "timing": {
        "client_log_timestamp": 123000
      },
      "action_id": "fake-action-id",
      "session_id": "fake-session-id",
      "auto_view_id": "fake-auto-view-id",
      "content_id": "foobar",
      "name": "ask-question",
      "action_type": "ASK_QUESTION",
      "element_id": "ask-question"
    }
    """
    XCTAssertEqual(
      try Event_Action(jsonString: expectedJSON),
      action
    )
  }
  
  func testLogAnswerQuestionAction() {
    metricsLogger.startSessionForTesting(userID: "foo")
    let item = Content(contentID: "foobar")
    metricsLogger.logAction(
      type: .answerQuestion,
      content: item,
      autoViewState: .fake
    )
    let action = assertSingletonList(
      metricsLogger.logMessagesForTesting,
      as: Event_Action.self
    )
    let expectedJSON = """
    {
      "timing": {
        "client_log_timestamp": 123000
      },
      "action_id": "fake-action-id",
      "session_id": "fake-session-id",
      "auto_view_id": "fake-auto-view-id",
      "content_id": "foobar",
      "name": "answer-question",
      "action_type": "ANSWER_QUESTION",
      "element_id": "answer-question"
    }
    """
    XCTAssertEqual(
      try Event_Action(jsonString: expectedJSON),
      action
    )
  }
  
  func testLogCompleteSignInAction() {
    metricsLogger.startSessionForTesting(userID: "foo")
    metricsLogger.logAction(
      type: .completeSignIn,
      content: nil,
      autoViewState: .fake
    )
    let action = assertSingletonList(
      metricsLogger.logMessagesForTesting,
      as: Event_Action.self
    )
    let expectedJSON = """
    {
      "timing": {
        "client_log_timestamp": 123000
      },
      "action_id": "fake-action-id",
      "session_id": "fake-session-id",
      "auto_view_id": "fake-auto-view-id",
      "name": "sign-in",
      "action_type": "COMPLETE_SIGN_IN",
      "element_id": "sign-in"
    }
    """
    XCTAssertEqual(
      try Event_Action(jsonString: expectedJSON),
      action
    )
  }

  func testLogCompleteSignUpAction() {
    metricsLogger.startSessionForTesting(userID: "foo")
    metricsLogger.logAction(
      type: .completeSignUp,
      content: nil,
      autoViewState: .fake
    )
    let action = assertSingletonList(
      metricsLogger.logMessagesForTesting,
      as: Event_Action.self
    )
    let expectedJSON = """
    {
      "timing": {
        "client_log_timestamp": 123000
      },
      "action_id": "fake-action-id",
      "session_id": "fake-session-id",
      "auto_view_id": "fake-auto-view-id",
      "name": "sign-up",
      "action_type": "COMPLETE_SIGN_UP",
      "element_id": "sign-up"
    }
    """
    XCTAssertEqual(
      try Event_Action(jsonString: expectedJSON),
      action
    )
  }

  func testLogCustomAction() {
    metricsLogger.startSessionForTesting(userID: "foo")
    let item = Content(contentID: "hello")
    metricsLogger.logAction(
      type: .custom,
      content: item,
      name: "foobar",
      autoViewState: .fake
    )
    let action = assertSingletonList(
      metricsLogger.logMessagesForTesting,
      as: Event_Action.self
    )
    let expectedJSON = """
    {
      "timing": {
        "client_log_timestamp": 123000
      },
      "action_id": "fake-action-id",
      "session_id": "fake-session-id",
      "auto_view_id": "fake-auto-view-id",
      "content_id": "hello",
      "name": "foobar",
      "action_type": "CUSTOM_ACTION_TYPE",
      "element_id": "foobar",
      "custom_action_type": "foobar"
    }
    """
    XCTAssertEqual(
      try Event_Action(jsonString: expectedJSON),
      action
    )
  }

  func testLogActionIDProvenances() {
    module.clientConfig.eventsIncludeIDProvenances = true
    metricsLogger = MetricsLogger(deps: module)
    metricsLogger.startSessionForTesting(userID: "foo")
    let item = Content(contentID: "", insertionID: "hello")
    metricsLogger.logAction(
      type: .navigate,
      content: item,
      autoViewState: .fake,
      impressionID: "fake-impression"
    )
    let action = assertSingletonList(
      metricsLogger.logMessagesForTesting,
      as: Event_Action.self
    )
    let expectedJSON = """
    {
      "timing": {
        "client_log_timestamp": 123000
      },
      "action_id": "fake-action-id",
      "session_id": "fake-session-id",
      "impression_id": "fake-impression",
      "insertion_id": "hello",
      "auto_view_id": "fake-auto-view-id",
      "name": "navigate",
      "action_type": "NAVIGATE",
      "element_id": "navigate",
      "navigate_action": {
      },
      "id_provenances": {
        "user_id_provenance": "PLATFORM_SPECIFIED",
        "log_user_id_provenance": "AUTOGENERATED",
        "session_id_provenance": "AUTOGENERATED",
        "view_id_provenance": "NULL",
        "impression_id_provenance": "AUTOGENERATED",
        "action_id_provenance": "AUTOGENERATED",
        "content_id_provenance": "EMPTY",
        "insertion_id_provenance": "AUTOGENERATED",
        "request_id_provenance": "NULL",
        "auto_view_id_provenance": "AUTOGENERATED"
      }
    }
    """
    XCTAssertEqual(
      try Event_Action(jsonString: expectedJSON),
      action
    )
  }

  func testLogActionClientPosition() {
    module.clientConfig.eventsIncludeClientPositions = true
    metricsLogger = MetricsLogger(deps: module)
    metricsLogger.startSessionForTesting(userID: "foo")
    let item = Content(contentID: "", insertionID: "hello")
    let collectionInteraction = CollectionInteraction(indexPath: [1, 8])
    metricsLogger.logAction(
      type: .navigate,
      content: item,
      autoViewState: .fake,
      collectionInteraction: collectionInteraction,
      impressionID: "fake-impression"
    )
    let action = assertSingletonList(
      metricsLogger.logMessagesForTesting,
      as: Event_Action.self
    )
    let expectedJSON = """
    {
      "timing": {
        "client_log_timestamp": 123000
      },
      "action_id": "fake-action-id",
      "session_id": "fake-session-id",
      "impression_id": "fake-impression",
      "insertion_id": "hello",
      "auto_view_id": "fake-auto-view-id",
      "name": "navigate",
      "action_type": "NAVIGATE",
      "element_id": "navigate",
      "navigate_action": {
      },
      "client_position": {
        "index": [1, 8]
      }
    }
    """
    XCTAssertEqual(
      try Event_Action(jsonString: expectedJSON),
      action
    )
  }

  func testLogViewController() {
    module.clientConfig.eventsIncludeClientPositions = true
    metricsLogger = MetricsLogger(deps: module)
    metricsLogger.startSessionForTesting(userID: "foo")
    let viewController = FakeScreenViewController()
    metricsLogger.logView(
      viewController: viewController,
      useCase: .search
    )
    let view = assertSingletonList(
      metricsLogger.logMessagesForTesting,
      as: Event_View.self
    )
    let expectedJSON = """
    {
      "timing": {
        "client_log_timestamp": 123000
      },
      "view_id": "\(idMap.viewID().stringValue!)",
      "session_id": "fake-session-id",
      "name": "FakeScreen",
      "use_case": "SEARCH",
      "locale": {
        "language_code": "en",
        "region_code": "US"
      },
      "view_type": "APP_SCREEN",
      "app_screen_view": {
      }
    }
    """
    XCTAssertEqual(
      try Event_View(jsonString: expectedJSON),
      view
    )
  }
  
  func testReadViewIDBeforeLogView() {
    // Because the creation of MetricsLogger changes the state
    // of the IDMap, we need to re-create MetricsLogger after
    // changing this flag on FakeIDMap.
    idMap.incrementCounts = true
    metricsLogger = MetricsLogger(deps: module)
    let initialViewID = metricsLogger.currentOrPendingViewID
    XCTAssertEqual("fake-view-id-1", initialViewID)
    metricsLogger.startSessionForTesting(userID: "foo")

    let viewController = FakeScreenViewController()
    metricsLogger.logView(
      viewController: viewController,
      useCase: .search
    )
    XCTAssertEqual(
      initialViewID,
      metricsLogger.currentOrPendingViewID
    )
  
    let viewController2 = FakeScreenViewController()
    metricsLogger.logView(
      viewController: viewController2,
      useCase: .search
    )
    XCTAssertNotEqual(initialViewID, metricsLogger.viewID)
  }
  
  func testViewLoggingChangeScreens() {
    // Because the creation of MetricsLogger changes the state
    // of the IDMap, we need to re-create MetricsLogger after
    // changing this flag on FakeIDMap.
    idMap.incrementCounts = true
    metricsLogger = MetricsLogger(deps: module)
    let initialViewID = metricsLogger.viewID
    metricsLogger.startSessionForTesting(userID: "foo")

    let vc1 = FakeScreenViewController()
    metricsLogger.logView(viewController: vc1, useCase: .search)

    let vc2 = FakeScreenViewController()
    metricsLogger.logView(viewController: vc2, useCase: .search)
    XCTAssertNotEqual(initialViewID, metricsLogger.viewID)

    metricsLogger.flush()

    uiState.viewControllerStack = [vc1, vc2]
    metricsLogger.logAction(
      type: .custom,
      content: nil,
      name: "hello"
    )

    uiState.viewControllerStack = [vc1]
    metricsLogger.logAction(
      type: .custom,
      content: nil,
      name: "goodbye"
    )

    // First action should be logged against vc2.
    XCTAssertEqual(3, metricsLogger.logMessagesForTesting.count)
    let message1 = metricsLogger.logMessagesForTesting[0]
    guard
      let action1 = message1 as? Event_Action
    else { XCTFail(); return }
    XCTAssertEqual("fake-view-id-2", action1.viewID)

    // Logger should notice vc2 was popped off stack and log a
    // synthetic view event for vc1. This view event should have
    // a new viewID.
    let message2 = metricsLogger.logMessagesForTesting[1]
    guard
      let view = message2 as? Event_View
    else { XCTFail(); return }
    XCTAssertEqual("fake-view-id-3", view.viewID)

    // Second action should be logged against vc1.
    let message3 = metricsLogger.logMessagesForTesting[2]
    guard
      let action2 = message3 as? Event_Action
    else { XCTFail(); return }
    XCTAssertEqual("fake-view-id-3", action2.viewID)
  }

  func testLogViewIDProvenances() {
    idMap.incrementCounts = true
    module.clientConfig.eventsIncludeIDProvenances = true
    metricsLogger = MetricsLogger(deps: module)
    metricsLogger.startSessionForTesting(userID: "foo")
    let viewController = FakeScreenViewController()
    metricsLogger.logView(
      viewController: viewController,
      useCase: .search
    )
    let message = metricsLogger.logMessagesForTesting.last!
    XCTAssertTrue(message is Event_View)
    let expectedJSON = """
    {
      "timing": {
        "client_log_timestamp": 123000
      },
      "view_id": "fake-view-id-1",
      "session_id": "fake-session-id-1",
      "name": "FakeScreen",
      "use_case": "SEARCH",
      "locale": {
        "language_code": "en",
        "region_code": "US"
      },
      "view_type": "APP_SCREEN",
      "app_screen_view": {
      },
      "id_provenances": {
        "user_id_provenance": "PLATFORM_SPECIFIED",
        "log_user_id_provenance": "AUTOGENERATED",
        "session_id_provenance": "AUTOGENERATED",
        "view_id_provenance": "AUTOGENERATED",
        "impression_id_provenance": "NULL",
        "action_id_provenance": "NULL",
        "content_id_provenance": "NULL",
        "insertion_id_provenance": "NULL",
        "request_id_provenance": "NULL",
        "auto_view_id_provenance": "NULL"
      }
    }
    """
    XCTAssertEqual(
      try Event_View(jsonString: expectedJSON),
      message as! Event_View
    )
  }

  func testLogAutoView() {
    metricsLogger.logUserID = "batman"
    metricsLogger.logAutoView(
      routeName: "fake-route-name",
      routeKey: "fake-route-key",
      autoViewID: "fake-auto-view-id"
    )
    metricsLogger.flush()
    let message = connection.messages.last?.message
    XCTAssertTrue(message is Event_LogRequest)
    let expectedJSON = """
    {
      "client_info": {
        "client_type": 2,
        "traffic_type": 1
      },
      "user_info": {
        "log_user_id": "batman"
      },
      \(FakeDeviceInfo.json),
      "auto_view": [
        {
          "timing": {
            "client_log_timestamp": 123000
          },
          "name": "fake-route-name",
          "auto_view_id": "fake-auto-view-id",
          "locale": {
            "language_code": "en",
            "region_code": "US"
          },
          "app_screen_view": {
          }
        }
      ]
    }
    """
    XCTAssertEqual(
      try Event_LogRequest(jsonString: expectedJSON),
      message as! Event_LogRequest
    )
  }

  func testLogAutoViewIDProvenances() {
    module.clientConfig.eventsIncludeIDProvenances = true
    metricsLogger = MetricsLogger(deps: module)
    metricsLogger.logUserID = "fake-log-user-id"
    metricsLogger.logAutoView(
      routeName: "fake-route-name",
      routeKey: "fake-route-key",
      autoViewID: "fake-auto-view-id"
    )
    let message = metricsLogger.logMessagesForTesting.last!
    XCTAssertTrue(message is Event_AutoView)
    let expectedJSON = """
    {
      "timing": {
        "client_log_timestamp": 123000
      },
      "name": "fake-route-name",
      "auto_view_id": "fake-auto-view-id",
      "locale": {
        "language_code": "en",
        "region_code": "US"
      },
      "app_screen_view": {
      },
      "id_provenances": {
        "user_id_provenance": "NULL",
        "log_user_id_provenance": "PLATFORM_SPECIFIED",
        "session_id_provenance": "NULL",
        "view_id_provenance": "NULL",
        "impression_id_provenance": "NULL",
        "action_id_provenance": "NULL",
        "content_id_provenance": "NULL",
        "insertion_id_provenance": "NULL",
        "request_id_provenance": "NULL",
        "auto_view_id_provenance": "AUTOGENERATED"
      }
    }
    """
    XCTAssertEqual(
      try Event_AutoView(jsonString: expectedJSON),
      message as! Event_AutoView
    )
  }

  func testLogAncestorIDHistory() {
    let flushInterval = config.loggingFlushInterval
    module.clientConfig.diagnosticsIncludeAncestorIDHistory = true
    clock.advance(to: 0.0)
    metricsLogger = MetricsLogger(deps: module)
    metricsLogger.startSessionAndLogUser(userID: "batman")
    metricsLogger.logAutoView(
      routeName: "fake-route-name",
      routeKey: "fake-route-key",
      autoViewID: "fake-auto-view-id"
    )
    metricsLogger.logView(
      name: "fake-route",
      viewID: "fake-view-id"
    )

    clock.advance(to: flushInterval + 10)
    let args = assertSingletonList(connection.messages)
    guard let logRequest = args.message as? Event_LogRequest else {
      XCTFail("Message sent to connection was not a LogRequest")
      return
    }

    let diagnostics = assertSingletonList(logRequest.diagnostics)
    let history = diagnostics.mobileDiagnostics.ancestorIDHistory

    let userHistory = assertSingletonList(history.logUserIDHistory)
    XCTAssertEqual("fake-log-user-id", userHistory.ancestorID)

    let sessionHistory = assertSingletonList(history.sessionIDHistory)
    XCTAssertEqual("fake-session-id", sessionHistory.ancestorID)

    let viewHistory = assertSingletonList(history.viewIDHistory)
    XCTAssertEqual("fake-view-id", viewHistory.ancestorID)

    let autoViewHistory = assertSingletonList(history.autoViewIDHistory)
    XCTAssertEqual("fake-auto-view-id", autoViewHistory.ancestorID)
  }

  private func assert(
    list: [(String, Error)],
    containsSingletonError error: MetricsLoggerError
  ) {
    XCTAssertEqual(
      [error.code],
      list.compactMap { $0.1.asErrorProperties()?.code }
    )
  }

  func testErrorMissingLogUserIDOnUser() {
    let listener = TestOperationMonitorListener()
    module.operationMonitor.addOperationMonitorListener(listener)

    metricsLogger.logUserID = nil
    metricsLogger.logUserForTesting(properties: nil)
    assert(
      list: listener.errors,
      containsSingletonError: .missingLogUserIDInUserMessage
    )
  }

  func testValidLogUserIDOnUser() {
    let listener = TestOperationMonitorListener()
    module.operationMonitor.addOperationMonitorListener(listener)

    metricsLogger.logUserID = "foo"
    metricsLogger.logUserForTesting(properties: nil)
    assertEmptyList(listener.errors)
  }

  func testErrorMissingLogUserIDOnLogRequest() {
    let listener = TestOperationMonitorListener()
    module.operationMonitor.addOperationMonitorListener(listener)
    metricsLogger.logUserID = nil

    metricsLogger.logImpression(
      content: Content(contentID: "foo", insertionID: "bar")
    )

    let flushInterval = config.loggingFlushInterval
    clock.advance(to: flushInterval + 10)

    assert(
      list: listener.errors,
      containsSingletonError: .missingLogUserIDInLogRequest
    )
  }

  func testValidLogUserIDOnLogRequest() {
    let listener = TestOperationMonitorListener()
    module.operationMonitor.addOperationMonitorListener(listener)
    metricsLogger.logUserID = "foo"

    metricsLogger.logImpression(
      content: Content(contentID: "foo", insertionID: "bar")
    )

    let flushInterval = config.loggingFlushInterval
    clock.advance(to: flushInterval + 10)

    assertEmptyList(listener.errors)
  }

  func testErrorBadImpression() {
    let listener = TestOperationMonitorListener()
    module.operationMonitor.addOperationMonitorListener(listener)

    metricsLogger.logImpression(
      content: Content(contentID: "foo", insertionID: "bar"),
      sourceType: .delivery
    )
    assertEmptyList(listener.errors)

    metricsLogger.logImpression(
      content: Content(contentID: "", insertionID: "")
    )
    assertEmptyList(listener.errors)

    metricsLogger.logImpression(
      content: Content(contentID: "", insertionID: ""),
      sourceType: .delivery
    )
    assert(
      list: listener.errors,
      containsSingletonError: .missingJoinableFieldsInImpression
    )
  }

  func testErrorBadAction() {
    let listener = TestOperationMonitorListener()
    module.operationMonitor.addOperationMonitorListener(listener)

    metricsLogger.logAction(
      type: .navigate,
      content: Content(contentID: "", insertionID: "")
    )

    assert(
      list: listener.errors,
      containsSingletonError: .missingJoinableFieldsInAction
    )
  }
}

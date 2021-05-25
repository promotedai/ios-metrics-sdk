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
    config.metricsLoggingURL = "http://fake.promoted.ai/metrics"
    clock.advance(to: 123)
    store.userID = "foobar"
    store.logUserID = "fake-log-user-id"
    metricsLogger = MetricsLogger(deps: module)
  }
  
  private func assertLoggerAndStoreInSync() {
    XCTAssertEqual(store.userID, metricsLogger.userIDForTesting)
    XCTAssertEqual(store.logUserID, metricsLogger.logUserID)
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
    let initialLogUserID = metricsLogger.logUserID
    XCTAssertEqual("fake-initial-id", initialLogUserID)
    let initialSessionID = metricsLogger.sessionID
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
    let initialLogUserID = metricsLogger.logUserID
    XCTAssertEqual("fake-initial-id", initialLogUserID)
    let initialSessionID = metricsLogger.sessionID
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
    let initialLogUserID = metricsLogger.logUserID
    XCTAssertEqual("fake-log-user-id-1", initialLogUserID)
    let initialSessionID = metricsLogger.sessionID
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
    let initialLogUserID = metricsLogger.logUserID
    XCTAssertEqual("fake-log-user-id-1", initialLogUserID)
    let initialSessionID = metricsLogger.sessionID
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
    XCTAssertEqual(1, clock.scheduledTimers.count)
    XCTAssertEqual(flushInterval, clock.scheduledTimers[0].timeInterval)
    XCTAssertEqual(1, metricsLogger.logMessagesForTesting.count)
    XCTAssertEqual(0, connection.messages.count)

    clock.advance(to: 5.0)
    metricsLogger.log(message: e)
    XCTAssertEqual(1, clock.scheduledTimers.count)
    XCTAssertEqual(2, metricsLogger.logMessagesForTesting.count)
    XCTAssertEqual(0, connection.messages.count)

    clock.advance(to: flushInterval + 10)
    XCTAssertEqual(0, clock.scheduledTimers.count)
    XCTAssertEqual(0, metricsLogger.logMessagesForTesting.count)
    XCTAssertEqual(1, connection.messages.count)
    guard let logRequest = connection.messages.first?.message as? Event_LogRequest else {
      XCTFail("Message sent to connection was not a LogRequest")
      return
    }
    XCTAssertNotEqual("", logRequest.userInfo.logUserID)

    connection.messages.removeAll()
    metricsLogger.log(message: e)
    XCTAssertEqual(1, clock.scheduledTimers.count)
    XCTAssertEqual(flushInterval, clock.scheduledTimers[0].timeInterval)
    XCTAssertEqual(1, metricsLogger.logMessagesForTesting.count)
    XCTAssertEqual(0, connection.messages.count)
  }

  func testFlushNoLogUserIDs() {
    metricsLogger = MetricsLogger(deps: module)

    let flushInterval = config.loggingFlushInterval

    let e = Event_Action()
    clock.advance(to: 0.0)
    metricsLogger.log(message: e)

    clock.advance(to: flushInterval + 10)
    XCTAssertEqual(1, connection.messages.count)
    guard let logRequest = connection.messages.first?.message as? Event_LogRequest else {
      XCTFail("Message sent to connection was not a LogRequest")
      return
    }
    XCTAssertEqual("", logRequest.userInfo.logUserID)
  }

  func testProperties() {
    metricsLogger.startSessionForTesting(userID: "foobar")
    var properties = Event_Impression()
    properties.impressionID = "foobar"
    metricsLogger.logUser(properties: properties)
    XCTAssertEqual(1, metricsLogger.logMessagesForTesting.count)
    let message = metricsLogger.logMessagesForTesting.last!
    XCTAssertTrue(message is Event_User)
    let propertiesData = (message as! Event_User).properties.structBytes
    do {
      let deserializedProps = try Event_Impression(serializedData: propertiesData)
      XCTAssertEqual("foobar", deserializedProps.impressionID)
    } catch {
      XCTFail("Exception when deserializing payload")
    }
  }

  func testLogUser() {
    metricsLogger.startSessionForTesting(userID: "foo")
    metricsLogger.logUser()
    XCTAssertEqual(1, metricsLogger.logMessagesForTesting.count)
    let message = metricsLogger.logMessagesForTesting.last!
    XCTAssertTrue(message is Event_User)
    let expectedJSON = """
    {
      "timing": {
        "client_log_timestamp": 123000
      }
    }
    """
    XCTAssertEqual(try Event_User(jsonString: expectedJSON),
                   message as! Event_User)
  }

  func testLogImpressionInsertionID() {
    metricsLogger.startSessionForTesting(userID: "foo")
    metricsLogger.logView(viewController: FakeScreenViewController())
    let item = Item(contentID: "foobar", insertionID: "insertion!")
    metricsLogger.logImpression(content: item)
    let message = metricsLogger.logMessagesForTesting.last!
    XCTAssertTrue(message is Event_Impression)
    let expectedJSON = """
    {
      "timing": {
        "client_log_timestamp": 123000
      },
      "impression_id": "fake-impression-id",
      "insertion_id": "insertion!",
      "content_id": "foobar",
      "session_id": "fake-session-id",
      "view_id": "fake-view-id"
    }
    """
    XCTAssertEqual(try Event_Impression(jsonString: expectedJSON),
                   message as! Event_Impression)
  }

  func testLogImpressionNoInsertionID() {
    metricsLogger.startSessionForTesting(userID: "foo")
    metricsLogger.logView(viewController: FakeScreenViewController())
    let item = Item(contentID: "foobar")
    metricsLogger.logImpression(content: item)
    let message = metricsLogger.logMessagesForTesting.last!
    XCTAssertTrue(message is Event_Impression)
    let expectedJSON = """
    {
      "timing": {
        "client_log_timestamp": 123000
      },
      "impression_id": "fake-impression-id",
      "content_id": "foobar",
      "session_id": "fake-session-id",
      "view_id": "fake-view-id"
    }
    """
    XCTAssertEqual(try Event_Impression(jsonString: expectedJSON),
                   message as! Event_Impression)
  }

  func testLogImpressionNoLogUserSessionViewIDs() {
    let item = Item(contentID: "foobar", insertionID: "insertion!")
    metricsLogger.logImpression(content: item)
    let message = metricsLogger.logMessagesForTesting.last!
    XCTAssertTrue(message is Event_Impression)
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
    XCTAssertEqual(try Event_Impression(jsonString: expectedJSON),
                   message as! Event_Impression)
  }

  func testLogNavigateAction() {
    metricsLogger.startSessionForTesting(userID: "foo")
    metricsLogger.logView(viewController: FakeScreenViewController())
    let viewController = FakeScreenViewController()
    let item = Item(contentID: "foobar")
    metricsLogger.logNavigateAction(viewController: viewController, forContent: item)
    let message = metricsLogger.logMessagesForTesting.last!
    XCTAssertTrue(message is Event_Action)
    let expectedJSON = """
    {
      "timing": {
        "client_log_timestamp": 123000
      },
      "action_id": "fake-action-id",
      "session_id": "fake-session-id",
      "view_id": "fake-view-id",
      "name": "FakeScreen",
      "action_type": "NAVIGATE",
      "element_id": "FakeScreen",
      "navigate_action": {
      }
    }
    """
    XCTAssertEqual(try Event_Action(jsonString: expectedJSON),
                   message as! Event_Action)
  }
  
  func testLogAddToCartAction() {
    metricsLogger.startSessionForTesting(userID: "foo")
    metricsLogger.logView(viewController: FakeScreenViewController())
    let item = Item(contentID: "foobar")
    metricsLogger.logAddToCartAction(item: item)
    let message = metricsLogger.logMessagesForTesting.last!
    XCTAssertTrue(message is Event_Action)
    let expectedJSON = """
    {
      "timing": {
        "client_log_timestamp": 123000
      },
      "action_id": "fake-action-id",
      "session_id": "fake-session-id",
      "view_id": "fake-view-id",
      "name": "add-to-cart",
      "action_type": "ADD_TO_CART",
      "element_id": "add-to-cart"
    }
    """
    XCTAssertEqual(try Event_Action(jsonString: expectedJSON),
                   message as! Event_Action)
  }
  
  func testLogRemoveFromCartAction() {
    metricsLogger.startSessionForTesting(userID: "foo")
    metricsLogger.logView(viewController: FakeScreenViewController())
    let item = Item(contentID: "foobar")
    metricsLogger.logRemoveFromCartAction(item: item)
    let message = metricsLogger.logMessagesForTesting.last!
    XCTAssertTrue(message is Event_Action)
    let expectedJSON = """
    {
      "timing": {
        "client_log_timestamp": 123000
      },
      "action_id": "fake-action-id",
      "session_id": "fake-session-id",
      "view_id": "fake-view-id",
      "name": "remove-from-cart",
      "action_type": "REMOVE_FROM_CART",
      "element_id": "remove-from-cart"
    }
    """
    XCTAssertEqual(try Event_Action(jsonString: expectedJSON),
                   message as! Event_Action)
  }
  
  func testLogCheckoutAction() {
    metricsLogger.startSessionForTesting(userID: "foo")
    metricsLogger.logView(viewController: FakeScreenViewController())
    metricsLogger.logCheckoutAction()
    let message = metricsLogger.logMessagesForTesting.last!
    XCTAssertTrue(message is Event_Action)
    let expectedJSON = """
    {
      "timing": {
        "client_log_timestamp": 123000
      },
      "action_id": "fake-action-id",
      "session_id": "fake-session-id",
      "view_id": "fake-view-id",
      "name": "checkout",
      "action_type": "CHECKOUT",
      "element_id": "checkout"
    }
    """
    XCTAssertEqual(try Event_Action(jsonString: expectedJSON),
                   message as! Event_Action)
  }
  
  func testLogPurchaseAction() {
    metricsLogger.startSessionForTesting(userID: "foo")
    metricsLogger.logView(viewController: FakeScreenViewController())
    let item = Item(contentID: "foobar")
    metricsLogger.logPurchaseAction(item: item)
    let message = metricsLogger.logMessagesForTesting.last!
    XCTAssertTrue(message is Event_Action)
    let expectedJSON = """
    {
      "timing": {
        "client_log_timestamp": 123000
      },
      "action_id": "fake-action-id",
      "session_id": "fake-session-id",
      "view_id": "fake-view-id",
      "name": "purchase",
      "action_type": "PURCHASE",
      "element_id": "purchase"
    }
    """
    XCTAssertEqual(try Event_Action(jsonString: expectedJSON),
                   message as! Event_Action)
  }
  
  func testLogShareAction() {
    metricsLogger.startSessionForTesting(userID: "foo")
    metricsLogger.logView(viewController: FakeScreenViewController())
    let item = Item(contentID: "foobar")
    metricsLogger.logShareAction(content: item)
    let message = metricsLogger.logMessagesForTesting.last!
    XCTAssertTrue(message is Event_Action)
    let expectedJSON = """
    {
      "timing": {
        "client_log_timestamp": 123000
      },
      "action_id": "fake-action-id",
      "session_id": "fake-session-id",
      "view_id": "fake-view-id",
      "name": "share",
      "action_type": "SHARE",
      "element_id": "share"
    }
    """
    XCTAssertEqual(try Event_Action(jsonString: expectedJSON),
                   message as! Event_Action)
  }

  func testLogLikeAction() {
    metricsLogger.startSessionForTesting(userID: "foo")
    metricsLogger.logView(viewController: FakeScreenViewController())
    let item = Item(contentID: "foobar")
    metricsLogger.logLikeAction(content: item)
    let message = metricsLogger.logMessagesForTesting.last!
    XCTAssertTrue(message is Event_Action)
    let expectedJSON = """
    {
      "timing": {
        "client_log_timestamp": 123000
      },
      "action_id": "fake-action-id",
      "session_id": "fake-session-id",
      "view_id": "fake-view-id",
      "name": "like",
      "action_type": "LIKE",
      "element_id": "like"
    }
    """
    XCTAssertEqual(try Event_Action(jsonString: expectedJSON),
                   message as! Event_Action)
  }

  func testLogUnlikeAction() {
    metricsLogger.startSessionForTesting(userID: "foo")
    metricsLogger.logView(viewController: FakeScreenViewController())
    let item = Item(contentID: "foobar")
    metricsLogger.logUnlikeAction(content: item)
    let message = metricsLogger.logMessagesForTesting.last!
    XCTAssertTrue(message is Event_Action)
    let expectedJSON = """
    {
      "timing": {
        "client_log_timestamp": 123000
      },
      "action_id": "fake-action-id",
      "session_id": "fake-session-id",
      "view_id": "fake-view-id",
      "name": "unlike",
      "action_type": "UNLIKE",
      "element_id": "unlike"
    }
    """
    XCTAssertEqual(try Event_Action(jsonString: expectedJSON),
                   message as! Event_Action)
  }
  
  func testLogCommentAction() {
    metricsLogger.startSessionForTesting(userID: "foo")
    metricsLogger.logView(viewController: FakeScreenViewController())
    let item = Item(contentID: "foobar")
    metricsLogger.logCommentAction(content: item)
    let message = metricsLogger.logMessagesForTesting.last!
    XCTAssertTrue(message is Event_Action)
    let expectedJSON = """
    {
      "timing": {
        "client_log_timestamp": 123000
      },
      "action_id": "fake-action-id",
      "session_id": "fake-session-id",
      "view_id": "fake-view-id",
      "name": "comment",
      "action_type": "COMMENT",
      "element_id": "comment"
    }
    """
    XCTAssertEqual(try Event_Action(jsonString: expectedJSON),
                   message as! Event_Action)
  }
  
  func testLogMakeOfferAction() {
    metricsLogger.startSessionForTesting(userID: "foo")
    metricsLogger.logView(viewController: FakeScreenViewController())
    let item = Item(contentID: "foobar")
    metricsLogger.logMakeOfferAction(item: item)
    let message = metricsLogger.logMessagesForTesting.last!
    XCTAssertTrue(message is Event_Action)
    let expectedJSON = """
    {
      "timing": {
        "client_log_timestamp": 123000
      },
      "action_id": "fake-action-id",
      "session_id": "fake-session-id",
      "view_id": "fake-view-id",
      "name": "make-offer",
      "action_type": "MAKE_OFFER",
      "element_id": "make-offer"
    }
    """
    XCTAssertEqual(try Event_Action(jsonString: expectedJSON),
                   message as! Event_Action)
  }
  
  func testLogAskQuestionAction() {
    metricsLogger.startSessionForTesting(userID: "foo")
    metricsLogger.logView(viewController: FakeScreenViewController())
    let item = Item(contentID: "foobar")
    metricsLogger.logAskQuestionAction(content: item)
    let message = metricsLogger.logMessagesForTesting.last!
    XCTAssertTrue(message is Event_Action)
    let expectedJSON = """
    {
      "timing": {
        "client_log_timestamp": 123000
      },
      "action_id": "fake-action-id",
      "session_id": "fake-session-id",
      "view_id": "fake-view-id",
      "name": "ask-question",
      "action_type": "ASK_QUESTION",
      "element_id": "ask-question"
    }
    """
    XCTAssertEqual(try Event_Action(jsonString: expectedJSON),
                   message as! Event_Action)
  }
  
  func testLogAnswerQuestionAction() {
    metricsLogger.startSessionForTesting(userID: "foo")
    metricsLogger.logView(viewController: FakeScreenViewController())
    let item = Item(contentID: "foobar")
    metricsLogger.logAnswerQuestionAction(content: item)
    let message = metricsLogger.logMessagesForTesting.last!
    XCTAssertTrue(message is Event_Action)
    let expectedJSON = """
    {
      "timing": {
        "client_log_timestamp": 123000
      },
      "action_id": "fake-action-id",
      "session_id": "fake-session-id",
      "view_id": "fake-view-id",
      "name": "answer-question",
      "action_type": "ANSWER_QUESTION",
      "element_id": "answer-question"
    }
    """
    XCTAssertEqual(try Event_Action(jsonString: expectedJSON),
                   message as! Event_Action)
  }
  
  func testLogCompleteSignInAction() {
    metricsLogger.startSessionForTesting(userID: "foo")
    metricsLogger.logView(viewController: FakeScreenViewController())
    metricsLogger.logCompleteSignInAction()
    let message = metricsLogger.logMessagesForTesting.last!
    XCTAssertTrue(message is Event_Action)
    let expectedJSON = """
    {
      "timing": {
        "client_log_timestamp": 123000
      },
      "action_id": "fake-action-id",
      "session_id": "fake-session-id",
      "view_id": "fake-view-id",
      "name": "sign-in",
      "action_type": "COMPLETE_SIGN_IN",
      "element_id": "sign-in"
    }
    """
    XCTAssertEqual(try Event_Action(jsonString: expectedJSON),
                   message as! Event_Action)
  }
  
  func testLogCompleteSignUpAction() {
    metricsLogger.startSessionForTesting(userID: "foo")
    metricsLogger.logView(viewController: FakeScreenViewController())
    metricsLogger.logCompleteSignUpAction()
    let message = metricsLogger.logMessagesForTesting.last!
    XCTAssertTrue(message is Event_Action)
    let expectedJSON = """
    {
      "timing": {
        "client_log_timestamp": 123000
      },
      "action_id": "fake-action-id",
      "session_id": "fake-session-id",
      "view_id": "fake-view-id",
      "name": "sign-up",
      "action_type": "COMPLETE_SIGN_UP",
      "element_id": "sign-up"
    }
    """
    XCTAssertEqual(try Event_Action(jsonString: expectedJSON),
                   message as! Event_Action)
  }
  
  func testLogViewController() {
    metricsLogger.startSessionForTesting(userID: "foo")
    let viewController = FakeScreenViewController()
    metricsLogger.logView(viewController: viewController, useCase: .search)
    let message = metricsLogger.logMessagesForTesting.last!
    XCTAssertTrue(message is Event_View)
    let expectedJSON = """
    {
      "timing": {
        "client_log_timestamp": 123000
      },
      "view_id": "\(idMap.viewID())",
      "session_id": "fake-session-id",
      "name": "FakeScreen",
      "use_case": "SEARCH",
      "device": {
        "device_type": "MOBILE",
        "brand": "Apple",
        "manufacturer": "Apple",
        "identifier": "iPhone",
        "os_version": "14.4.1",
        "locale": {
          "language_code": "en",
          "region_code": "US"
        },
        "screen": {
          "size": {
            "width": 1024,
            "height": 768
          },
          "scale": 2.0
        }
      },
      "view_type": "APP_SCREEN",
      "app_screen_view": {
      }
    }
    """
    XCTAssertEqual(try Event_View(jsonString: expectedJSON),
                   message as! Event_View)
  }
  
  func testReadViewIDBeforeLogView() {
    idMap.incrementCounts = true
    let initialViewID = metricsLogger.viewID
    XCTAssertEqual("fake-view-id-1", initialViewID)
    metricsLogger.startSessionForTesting(userID: "foo")

    let viewController = FakeScreenViewController()
    metricsLogger.logView(viewController: viewController, useCase: .search)
    XCTAssertEqual(initialViewID, metricsLogger.viewID)
  
    let viewController2 = FakeScreenViewController()
    metricsLogger.logView(viewController: viewController2, useCase: .search)
    XCTAssertNotEqual(initialViewID, metricsLogger.viewID)
  }
  
  func testViewLoggingChangeScreens() {
    idMap.incrementCounts = true
    let initialViewID = metricsLogger.viewID
    metricsLogger.startSessionForTesting(userID: "foo")

    let vc1 = FakeScreenViewController()
    metricsLogger.logView(viewController: vc1, useCase: .search)

    let vc2 = FakeScreenViewController()
    metricsLogger.logView(viewController: vc2, useCase: .search)
    XCTAssertNotEqual(initialViewID, metricsLogger.viewID)

    metricsLogger.flush()

    uiState.viewControllers = [vc1, vc2]
    metricsLogger.logAction(name: "hello")

    uiState.viewControllers = [vc1]
    metricsLogger.logAction(name: "goodbye")

    // First action should be logged against vc2.
    XCTAssertEqual(3, metricsLogger.logMessagesForTesting.count)
    let message1 = metricsLogger.logMessagesForTesting[0]
    guard let action1 = message1 as? Event_Action else { XCTFail(); return }
    XCTAssertEqual("fake-view-id-2", action1.viewID)

    // Logger should notice vc2 was popped off stack and log a
    // synthetic view event for vc1. This view event should have
    // a new viewID.
    let message2 = metricsLogger.logMessagesForTesting[1]
    guard let view = message2 as? Event_View else { XCTFail(); return }
    XCTAssertEqual("fake-view-id-3", view.viewID)

    // Second action should be logged against vc1.
    let message3 = metricsLogger.logMessagesForTesting[2]
    guard let action2 = message3 as? Event_Action else { XCTFail(); return }
    XCTAssertEqual("fake-view-id-3", action2.viewID)
  }
}

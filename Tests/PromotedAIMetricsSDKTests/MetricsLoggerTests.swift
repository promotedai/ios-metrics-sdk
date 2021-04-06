import Foundation
import SwiftProtobuf
import TestHelpers
import XCTest

@testable import PromotedAIMetricsSDK
@testable import TestHelpers

final class MetricsLoggerTests: XCTestCase {
  
  #if canImport(UIKit)
  private class FakeScreenViewController: UIViewController {}
  #else
  private class FakeScreenViewController {}
  #endif
  
  private var config: ClientConfig?
  private var connection: FakeNetworkConnection?
  private var clock: FakeClock?
  private var idMap: FakeIDMap?
  private var store: FakePersistentStore?
  private var metricsLogger: MetricsLogger?

  public override func setUp() {
    super.setUp()
    config = ClientConfig()
    config!.metricsLoggingURL = "http://fake.promoted.ai/metrics"
    connection = FakeNetworkConnection()
    clock = FakeClock()
    idMap = FakeIDMap()
    store = FakePersistentStore()
    store!.userID = nil
    store!.logUserID = nil
    metricsLogger = MetricsLogger(clientConfig: config!,
                                  clock: clock!,
                                  connection: connection!,
                                  deviceInfo: FakeDeviceInfo(),
                                  idMap: idMap!,
                                  store: store!)
  }
  
  private func assertLoggerAndStoreInSync() {
    XCTAssertEqual(store!.userID, metricsLogger!.userID)
    XCTAssertEqual(store!.logUserID, metricsLogger!.logUserID)
  }
  
  func testStartSession() {
    idMap!.incrementCounts = true
    metricsLogger!.startSession(userID: "foobar")
    XCTAssertEqual("foobar", store!.userID)
    XCTAssertNotNil(store!.logUserID)
    assertLoggerAndStoreInSync()
  }
  
  func testStartSessionMultiple() {
    idMap!.incrementCounts = true
    metricsLogger!.startSession(userID: "foobar")
    XCTAssertEqual("foobar", store!.userID)
    XCTAssertNotNil(store!.logUserID)
    assertLoggerAndStoreInSync()
    
    let previousLogUserID = store!.logUserID
    metricsLogger!.startSession(userID: "foobar")
    XCTAssertEqual("foobar", store!.userID)
    XCTAssertEqual(previousLogUserID, store!.logUserID)
    assertLoggerAndStoreInSync()
    
    metricsLogger!.startSession(userID: "foobarbaz")
    XCTAssertEqual("foobarbaz", store!.userID)
    XCTAssertNotNil(store!.logUserID)
    XCTAssertNotEqual(previousLogUserID, store!.logUserID)
    assertLoggerAndStoreInSync()
  }
  
  func testStartSessionSignedOut() {
    idMap!.incrementCounts = true
    metricsLogger!.startSessionSignedOut()
    XCTAssertNil(store!.userID)
    XCTAssertNotNil(store!.logUserID)
    assertLoggerAndStoreInSync()
  }
  
  func testStartSessionSignInThenSignOut() {
    idMap!.incrementCounts = true
    metricsLogger!.startSession(userID: "foobar")
    XCTAssertEqual("foobar", store!.userID)
    XCTAssertNotNil(store!.logUserID)
    assertLoggerAndStoreInSync()
    
    let previousLogUserID = store!.logUserID
    metricsLogger!.startSessionSignedOut()
    XCTAssertNil(store!.userID)
    XCTAssertNotNil(store!.logUserID)
    XCTAssertNotEqual(previousLogUserID, store!.logUserID)
    assertLoggerAndStoreInSync()
  }
  
  func testStartSessionSignOutThenSignIn() {
    idMap!.incrementCounts = true
    metricsLogger!.startSessionSignedOut()
    XCTAssertNil(store!.userID)
    XCTAssertNotNil(store!.logUserID)
    assertLoggerAndStoreInSync()
    
    let previousLogUserID = store!.logUserID
    metricsLogger!.startSession(userID: "foobar")
    XCTAssertEqual("foobar", store!.userID)
    XCTAssertNotNil(store!.logUserID)
    XCTAssertNotEqual(previousLogUserID, store!.logUserID)
    assertLoggerAndStoreInSync()
  }
  
  func testBatchFlush() {
    let flushInterval = config!.loggingFlushInterval
    metricsLogger!.startSession(userID: "foobar")
    let e = Event_Action()

    clock!.advance(to: 0.0)
    metricsLogger!.log(message: e)
    XCTAssertEqual(1, clock!.scheduledTimers.count)
    XCTAssertEqual(flushInterval, clock!.scheduledTimers[0].timeInterval)
    XCTAssertEqual(1, metricsLogger!.logMessages.count)
    XCTAssertEqual(0, connection!.messages.count)

    clock!.advance(to: 5.0)
    metricsLogger!.log(message: e)
    XCTAssertEqual(1, clock!.scheduledTimers.count)
    XCTAssertEqual(2, metricsLogger!.logMessages.count)
    XCTAssertEqual(0, connection!.messages.count)

    clock!.advance(to: flushInterval + 10)
    XCTAssertEqual(0, clock!.scheduledTimers.count)
    XCTAssertEqual(0, metricsLogger!.logMessages.count)
    XCTAssertEqual(1, connection!.messages.count)

    connection!.messages.removeAll()
    metricsLogger!.log(message: e)
    XCTAssertEqual(1, clock!.scheduledTimers.count)
    XCTAssertEqual(flushInterval, clock!.scheduledTimers[0].timeInterval)
    XCTAssertEqual(1, metricsLogger!.logMessages.count)
    XCTAssertEqual(0, connection!.messages.count)
  }
  
  func testProperties() {
    metricsLogger!.startSession(userID: "foobar")
    var properties = Event_Impression()
    properties.impressionID = "foobar"
    metricsLogger!.logUser(properties: properties)
    XCTAssertEqual(1, metricsLogger!.logMessages.count)
    let message = metricsLogger!.logMessages[0]
    XCTAssertTrue(message is Event_User)
    let propertiesData = (message as! Event_User).properties.structBytes
    do {
      let deserializedProps = try Event_Impression(serializedData: propertiesData)
      XCTAssertEqual("foobar", deserializedProps.impressionID)
    } catch {
      XCTFail("Exception when deserializing payload")
    }
  }
  
  func testDisableLogging() {
    // Logging enabled.
    metricsLogger!.startSession(userID: "foobar")
    metricsLogger!.logUser()
    XCTAssertEqual(1, metricsLogger!.logMessages.count)
    let message = metricsLogger!.logMessages[0]
    XCTAssertTrue(message is Event_User)
    metricsLogger!.flush()
    XCTAssertEqual(1, connection!.messages.count)

    // Logging disabled.
    connection!.messages.removeAll()
    config!.loggingEnabled = false
    metricsLogger = MetricsLogger(clientConfig: config!,
                                  clock: clock!,
                                  connection: connection!,
                                  deviceInfo: FakeDeviceInfo(),
                                  idMap: SHA1IDMap.instance,
                                  store: store!)
    metricsLogger!.startSession(userID: "foobar")
    metricsLogger!.logUser()
    metricsLogger!.flush()
    XCTAssertEqual(0, connection!.messages.count)
  }
  
  func testLogUser() {
    metricsLogger!.startSession(userID: "foo")
    metricsLogger!.logUser()
    XCTAssertEqual(1, metricsLogger!.logMessages.count)
    let message = metricsLogger!.logMessages[0]
    XCTAssertTrue(message is Event_User)
    let expectedJSON = """
    {
    }
    """
    XCTAssertEqual(try Event_User(jsonString: expectedJSON),
                   message as! Event_User)
  }
  
  func testLogImpressionInsertionID() {
    metricsLogger!.startSession(userID: "foo")
    let item = Item(contentID: "foobar", insertionID: "insertion!")
    metricsLogger!.logImpression(content: item)
    let message = metricsLogger!.logMessages[0]
    XCTAssertTrue(message is Event_Impression)
    let impressionID = idMap!.impressionIDOrNil(insertionID: "insertion!",
                                                contentID: "foobar",
                                                logUserID: "fake-log-user-id")!
    let expectedJSON = """
    {
      "impression_id": "\(impressionID)",
      "insertion_id": "insertion!",
      "content_id": "\(idMap!.contentID(clientID: "foobar"))",
      "session_id": "fake-session-id"
    }
    """
    XCTAssertEqual(try Event_Impression(jsonString: expectedJSON),
                   message as! Event_Impression)
  }
  
  func testLogImpressionNoInsertionID() {
    metricsLogger!.startSession(userID: "foo")
    let item = Item(contentID: "foobar")
    metricsLogger!.logImpression(content: item)
    let message = metricsLogger!.logMessages[0]
    XCTAssertTrue(message is Event_Impression)
    let impressionID = idMap!.impressionIDOrNil(insertionID: nil,
                                                contentID: "foobar",
                                                logUserID: "fake-log-user-id")!
    let expectedJSON = """
    {
      "impression_id": "\(impressionID)",
      "content_id": "\(idMap!.contentID(clientID: "foobar"))",
      "session_id": "fake-session-id"
    }
    """
    XCTAssertEqual(try Event_Impression(jsonString: expectedJSON),
                   message as! Event_Impression)
  }
  
  func testLogNavigateAction() {
    metricsLogger!.startSession(userID: "foo")
    let viewController = FakeScreenViewController()
    let item = Item(contentID: "foobar")
    metricsLogger!.logNavigateAction(viewController: viewController, forContent: item)
    let message = metricsLogger!.logMessages[0]
    XCTAssertTrue(message is Event_Action)
    let impressionID = idMap!.impressionIDOrNil(insertionID: nil,
                                                contentID: "foobar",
                                                logUserID: "fake-log-user-id")!
    let expectedJSON = """
    {
      "action_id": "fake-action-id",
      "impression_id": "\(impressionID)",
      "session_id": "fake-session-id",
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
    metricsLogger!.startSession(userID: "foo")
    let item = Item(contentID: "foobar")
    metricsLogger!.logAddToCartAction(item: item)
    let message = metricsLogger!.logMessages[0]
    XCTAssertTrue(message is Event_Action)
    let impressionID = idMap!.impressionIDOrNil(insertionID: nil,
                                                contentID: "foobar",
                                                logUserID: "fake-log-user-id")!
    let expectedJSON = """
    {
      "action_id": "fake-action-id",
      "impression_id": "\(impressionID)",
      "session_id": "fake-session-id",
      "name": "add-to-cart",
      "action_type": "ADD_TO_CART",
      "element_id": "add-to-cart"
    }
    """
    XCTAssertEqual(try Event_Action(jsonString: expectedJSON),
                   message as! Event_Action)
  }
  
  func testLogRemoveFromCartAction() {
    metricsLogger!.startSession(userID: "foo")
    let item = Item(contentID: "foobar")
    metricsLogger!.logRemoveFromCartAction(item: item)
    let message = metricsLogger!.logMessages[0]
    XCTAssertTrue(message is Event_Action)
    let impressionID = idMap!.impressionIDOrNil(insertionID: nil,
                                                contentID: "foobar",
                                                logUserID: "fake-log-user-id")!
    let expectedJSON = """
    {
      "action_id": "fake-action-id",
      "impression_id": "\(impressionID)",
      "session_id": "fake-session-id",
      "name": "remove-from-cart",
      "action_type": "REMOVE_FROM_CART",
      "element_id": "remove-from-cart"
    }
    """
    XCTAssertEqual(try Event_Action(jsonString: expectedJSON),
                   message as! Event_Action)
  }
  
  func testLogCheckoutAction() {
    metricsLogger!.startSession(userID: "foo")
    metricsLogger!.logCheckoutAction()
    let message = metricsLogger!.logMessages[0]
    XCTAssertTrue(message is Event_Action)
    let expectedJSON = """
    {
      "action_id": "fake-action-id",
      "session_id": "fake-session-id",
      "name": "checkout",
      "action_type": "CHECKOUT",
      "element_id": "checkout"
    }
    """
    XCTAssertEqual(try Event_Action(jsonString: expectedJSON),
                   message as! Event_Action)
  }
  
  func testLogPurchaseAction() {
    metricsLogger!.startSession(userID: "foo")
    let item = Item(contentID: "foobar")
    metricsLogger!.logPurchaseAction(item: item)
    let message = metricsLogger!.logMessages[0]
    XCTAssertTrue(message is Event_Action)
    let impressionID = idMap!.impressionIDOrNil(insertionID: nil,
                                                contentID: "foobar",
                                                logUserID: "fake-log-user-id")!
    let expectedJSON = """
    {
      "action_id": "fake-action-id",
      "impression_id": "\(impressionID)",
      "session_id": "fake-session-id",
      "name": "purchase",
      "action_type": "PURCHASE",
      "element_id": "purchase"
    }
    """
    XCTAssertEqual(try Event_Action(jsonString: expectedJSON),
                   message as! Event_Action)
  }
  
  func testLogShareAction() {
    metricsLogger!.startSession(userID: "foo")
    let item = Item(contentID: "foobar")
    metricsLogger!.logShareAction(content: item)
    let message = metricsLogger!.logMessages[0]
    XCTAssertTrue(message is Event_Action)
    let impressionID = idMap!.impressionIDOrNil(insertionID: nil,
                                                contentID: "foobar",
                                                logUserID: "fake-log-user-id")!
    let expectedJSON = """
    {
      "action_id": "fake-action-id",
      "impression_id": "\(impressionID)",
      "session_id": "fake-session-id",
      "name": "share",
      "action_type": "SHARE",
      "element_id": "share"
    }
    """
    XCTAssertEqual(try Event_Action(jsonString: expectedJSON),
                   message as! Event_Action)
  }

  func testLogLikeAction() {
    metricsLogger!.startSession(userID: "foo")
    let item = Item(contentID: "foobar")
    metricsLogger!.logLikeAction(content: item)
    let message = metricsLogger!.logMessages[0]
    XCTAssertTrue(message is Event_Action)
    let impressionID = idMap!.impressionIDOrNil(insertionID: nil,
                                                contentID: "foobar",
                                                logUserID: "fake-log-user-id")!
    let expectedJSON = """
    {
      "action_id": "fake-action-id",
      "impression_id": "\(impressionID)",
      "session_id": "fake-session-id",
      "name": "like",
      "action_type": "LIKE",
      "element_id": "like"
    }
    """
    XCTAssertEqual(try Event_Action(jsonString: expectedJSON),
                   message as! Event_Action)
  }

  func testLogUnlikeAction() {
    metricsLogger!.startSession(userID: "foo")
    let item = Item(contentID: "foobar")
    metricsLogger!.logUnlikeAction(content: item)
    let message = metricsLogger!.logMessages[0]
    XCTAssertTrue(message is Event_Action)
    let impressionID = idMap!.impressionIDOrNil(insertionID: nil,
                                                contentID: "foobar",
                                                logUserID: "fake-log-user-id")!
    let expectedJSON = """
    {
      "action_id": "fake-action-id",
      "impression_id": "\(impressionID)",
      "session_id": "fake-session-id",
      "name": "unlike",
      "action_type": "UNLIKE",
      "element_id": "unlike"
    }
    """
    XCTAssertEqual(try Event_Action(jsonString: expectedJSON),
                   message as! Event_Action)
  }
  
  func testLogCommentAction() {
    metricsLogger!.startSession(userID: "foo")
    let item = Item(contentID: "foobar")
    metricsLogger!.logCommentAction(content: item)
    let message = metricsLogger!.logMessages[0]
    XCTAssertTrue(message is Event_Action)
    let impressionID = idMap!.impressionIDOrNil(insertionID: nil,
                                                contentID: "foobar",
                                                logUserID: "fake-log-user-id")!
    let expectedJSON = """
    {
      "action_id": "fake-action-id",
      "impression_id": "\(impressionID)",
      "session_id": "fake-session-id",
      "name": "comment",
      "action_type": "COMMENT",
      "element_id": "comment"
    }
    """
    XCTAssertEqual(try Event_Action(jsonString: expectedJSON),
                   message as! Event_Action)
  }
  
  func testLogMakeOfferAction() {
    metricsLogger!.startSession(userID: "foo")
    let item = Item(contentID: "foobar")
    metricsLogger!.logMakeOfferAction(item: item)
    let message = metricsLogger!.logMessages[0]
    XCTAssertTrue(message is Event_Action)
    let impressionID = idMap!.impressionIDOrNil(insertionID: nil,
                                                contentID: "foobar",
                                                logUserID: "fake-log-user-id")!
    let expectedJSON = """
    {
      "action_id": "fake-action-id",
      "impression_id": "\(impressionID)",
      "session_id": "fake-session-id",
      "name": "make-offer",
      "action_type": "MAKE_OFFER",
      "element_id": "make-offer"
    }
    """
    XCTAssertEqual(try Event_Action(jsonString: expectedJSON),
                   message as! Event_Action)
  }
  
  func testLogAskQuestionAction() {
    metricsLogger!.startSession(userID: "foo")
    let item = Item(contentID: "foobar")
    metricsLogger!.logAskQuestionAction(content: item)
    let message = metricsLogger!.logMessages[0]
    XCTAssertTrue(message is Event_Action)
    let impressionID = idMap!.impressionIDOrNil(insertionID: nil,
                                                contentID: "foobar",
                                                logUserID: "fake-log-user-id")!
    let expectedJSON = """
    {
      "action_id": "fake-action-id",
      "impression_id": "\(impressionID)",
      "session_id": "fake-session-id",
      "name": "ask-question",
      "action_type": "ASK_QUESTION",
      "element_id": "ask-question"
    }
    """
    XCTAssertEqual(try Event_Action(jsonString: expectedJSON),
                   message as! Event_Action)
  }
  
  func testLogAnswerQuestionAction() {
    metricsLogger!.startSession(userID: "foo")
    let item = Item(contentID: "foobar")
    metricsLogger!.logAnswerQuestionAction(content: item)
    let message = metricsLogger!.logMessages[0]
    XCTAssertTrue(message is Event_Action)
    let impressionID = idMap!.impressionIDOrNil(insertionID: nil,
                                                contentID: "foobar",
                                                logUserID: "fake-log-user-id")!
    let expectedJSON = """
    {
      "action_id": "fake-action-id",
      "impression_id": "\(impressionID)",
      "session_id": "fake-session-id",
      "name": "answer-question",
      "action_type": "ANSWER_QUESTION",
      "element_id": "answer-question"
    }
    """
    XCTAssertEqual(try Event_Action(jsonString: expectedJSON),
                   message as! Event_Action)
  }
  
  func testLogCompleteSignInAction() {
    metricsLogger!.startSession(userID: "foo")
    metricsLogger!.logCompleteSignInAction()
    let message = metricsLogger!.logMessages[0]
    XCTAssertTrue(message is Event_Action)
    let expectedJSON = """
    {
      "action_id": "fake-action-id",
      "session_id": "fake-session-id",
      "name": "sign-in",
      "action_type": "COMPLETE_SIGN_IN",
      "element_id": "sign-in"
    }
    """
    XCTAssertEqual(try Event_Action(jsonString: expectedJSON),
                   message as! Event_Action)
  }
  
  func testLogCompleteSignUpAction() {
    metricsLogger!.startSession(userID: "foo")
    metricsLogger!.logCompleteSignUpAction()
    let message = metricsLogger!.logMessages[0]
    XCTAssertTrue(message is Event_Action)
    let expectedJSON = """
    {
      "action_id": "fake-action-id",
      "session_id": "fake-session-id",
      "name": "sign-up",
      "action_type": "COMPLETE_SIGN_UP",
      "element_id": "sign-up"
    }
    """
    XCTAssertEqual(try Event_Action(jsonString: expectedJSON),
                   message as! Event_Action)
  }
  
  func testLogViewController() {
    metricsLogger!.startSession(userID: "foo")
    let viewController = FakeScreenViewController()
    metricsLogger!.logView(viewController: viewController, useCase: .search)
    let message = metricsLogger!.logMessages[0]
    XCTAssertTrue(message is Event_View)
    let expectedJSON = """
    {
      "view_id": "\(idMap!.viewID())",
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

  static var allTests = [
    ("testStartSession", testStartSession),
    ("testStartSessionMultiple", testStartSessionMultiple),
    ("testStartSessionSignedOut", testStartSessionSignedOut),
    ("testStartSessionSignInThenSignOut", testStartSessionSignInThenSignOut),
    ("testStartSessionSignOutThenSignIn", testStartSessionSignOutThenSignIn),
    ("testBatchFlush", testBatchFlush),
    ("testProperties", testProperties),
    ("testLogUser", testLogUser),
    ("testLogImpressionInsertionID", testLogImpressionInsertionID),
    ("testLogImpressionNoInsertionID", testLogImpressionNoInsertionID),
    ("testLogNavigateAction", testLogNavigateAction),
    ("testLogAddToCartAction", testLogAddToCartAction),
    ("testLogRemoveFromCartAction", testLogRemoveFromCartAction),
    ("testLogCheckoutAction", testLogCheckoutAction),
    ("testLogPurchaseAction", testLogPurchaseAction),
    ("testLogShareAction", testLogShareAction),
    ("testLogLikeAction", testLogLikeAction),
    ("testLogUnlikeAction", testLogUnlikeAction),
    ("testLogCommentAction", testLogCommentAction),
    ("testLogMakeOfferAction", testLogMakeOfferAction),
    ("testLogAskQuestionAction", testLogAskQuestionAction),
    ("testLogAnswerQuestionAction", testLogAnswerQuestionAction),
    ("testLogCompleteSignInAction", testLogCompleteSignInAction),
    ("testLogCompleteSignUpAction", testLogCompleteSignUpAction),
    ("testLogViewController", testLogViewController),
  ]
}

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
    metricsLogger!.startSession(userID: "foobar")
    XCTAssertEqual("foobar", store!.userID)
    XCTAssertNotNil(store!.logUserID)
    assertLoggerAndStoreInSync()
  }
  
  func testStartSessionMultiple() {
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
    metricsLogger!.startSessionSignedOut()
    XCTAssertNil(store!.userID)
    XCTAssertNotNil(store!.logUserID)
    assertLoggerAndStoreInSync()
  }
  
  func testStartSessionSignInThenSignOut() {
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
  
  func testCustomData() {
    metricsLogger!.startSession(userID: "foobar")
    var customData = Event_Impression()
    customData.impressionID = "foobar"
    metricsLogger!.logUser(data: customData)
    XCTAssertEqual(1, metricsLogger!.logMessages.count)
    let message = metricsLogger!.logMessages[0]
    XCTAssertTrue(message is Event_User)
    let payloadData = (message as! Event_User).data.dataBytes
    do {
      let deserializedPayload = try Event_Impression(serializedData: payloadData)
      XCTAssertEqual("foobar", deserializedPayload.impressionID)
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
  
  func testLogImpression() {
    metricsLogger!.startSession(userID: "foo")
    let item = Item(contentID: "foobar")
    metricsLogger!.logImpression(content: item)
    let message = metricsLogger!.logMessages[0]
    XCTAssertTrue(message is Event_Impression)
    let expectedJSON = """
    {
      "impression_id": "\(idMap!.impressionID(contentID: "foobar"))",
      "session_id": "fake-session-id"
    }
    """
    XCTAssertEqual(try Event_Impression(jsonString: expectedJSON),
                   message as! Event_Impression)
  }
  
  func testLogClickToLike() {
    metricsLogger!.startSession(userID: "foo")
    let item = Item(contentID: "foobar")
    metricsLogger!.logClickToLike(content: item, didLike: true)
    let message = metricsLogger!.logMessages[0]
    XCTAssertTrue(message is Event_Action)
    let expectedJSON = """
    {
      "action_id": "fake-action-id",
      "impression_id": "\(idMap!.impressionID(contentID: "foobar"))",
      "session_id": "fake-session-id",
      "name": "like",
      "action_type": "LIKE",
      "element_id": "like"
    }
    """
    XCTAssertEqual(try Event_Action(jsonString: expectedJSON),
                   message as! Event_Action)
  }

  func testLogClickToUnlike() {
    metricsLogger!.startSession(userID: "foo")
    let item = Item(contentID: "foobar")
    metricsLogger!.logClickToLike(content: item, didLike: false)
    let message = metricsLogger!.logMessages[0]
    XCTAssertTrue(message is Event_Action)
    let expectedJSON = """
    {
      "action_id": "fake-action-id",
      "impression_id": "\(idMap!.impressionID(contentID: "foobar"))",
      "session_id": "fake-session-id",
      "name": "unlike",
      "action_type": "LIKE",
      "element_id": "unlike"
    }
    """
    XCTAssertEqual(try Event_Action(jsonString: expectedJSON),
                   message as! Event_Action)
  }
  
  func testLogClickToShowViewController() {
    metricsLogger!.startSession(userID: "foo")
    let viewController = FakeScreenViewController()
    let item = Item(contentID: "foobar")
    metricsLogger!.logClickToShow(viewController: viewController, forContent: item)
    let message = metricsLogger!.logMessages[0]
    XCTAssertTrue(message is Event_Action)
    let expectedJSON = """
    {
      "action_id": "fake-action-id",
      "impression_id": "\(idMap!.impressionID(contentID: "foobar"))",
      "session_id": "fake-session-id",
      "name": "FakeScreen",
      "action_type": "CLICK",
      "element_id": "FakeScreen",
      "click": {
      }
    }
    """
    XCTAssertEqual(try Event_Action(jsonString: expectedJSON),
                   message as! Event_Action)
  }
  
  func testLogClickToSignUp() {
    metricsLogger!.startSession(userID: "foobar")
    metricsLogger!.logClickToSignUp(userID: "foo")
    let message = metricsLogger!.logMessages[0]
    XCTAssertTrue(message is Event_Action)
    let expectedJSON = """
    {
      "action_id": "fake-action-id",
      "impression_id": "\(idMap!.impressionID(contentID: "foo"))",
      "session_id": "fake-session-id",
      "name": "sign-up",
      "action_type": "CLICK",
      "element_id": "sign-up",
      "click": {
      }
    }
    """
    XCTAssertEqual(try Event_Action(jsonString: expectedJSON),
                   message as! Event_Action)
  }
  
  func testLogClickToPurchase() {
    metricsLogger!.startSession(userID: "foo")
    let item = Item(contentID: "foobar")
    metricsLogger!.logClickToPurchase(item: item)
    let message = metricsLogger!.logMessages[0]
    XCTAssertTrue(message is Event_Action)
    let expectedJSON = """
    {
      "action_id": "fake-action-id",
      "impression_id": "\(idMap!.impressionID(contentID: "foobar"))",
      "session_id": "fake-session-id",
      "name": "purchase",
      "action_type": "PURCHASE",
      "element_id": "purchase"
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
      "view_id": "\(idMap!.viewID(viewName: "FakeScreen"))",
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
    ("testCustomData", testCustomData),
    ("testLogUser", testLogUser),
    ("testLogImpression", testLogImpression),
    ("testLogClickToLike", testLogClickToLike),
    ("testLogClickToUnlike", testLogClickToUnlike),
    ("testLogClickToShowViewController", testLogClickToShowViewController),
    ("testLogClickToSignUp", testLogClickToSignUp),
    ("testLogClickToPurchase", testLogClickToPurchase),
    ("testLogViewController", testLogViewController),
  ]
}

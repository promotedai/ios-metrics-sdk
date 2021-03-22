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
    let e = Event_Click()

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
  
  func testPayload() {
    var payload = Event_Impression()
    payload.impressionID = "foobar"
    metricsLogger!.logUser(payload: payload)
    XCTAssertEqual(1, metricsLogger!.logMessages.count)
    let message = metricsLogger!.logMessages[0]
    XCTAssertTrue(message is Event_User)
    let payloadData = (message as! Event_User).payload.payloadBytes
    do {
      let deserializedPayload = try Event_Impression(serializedData: payloadData)
      XCTAssertEqual("foobar", deserializedPayload.impressionID)
    } catch {
      XCTFail("Exception when deserializing payload")
    }
  }
  
  func testDisableLogging() {
    // Logging enabled.
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
                                  idMap: SHA1IDMap.instance,
                                  store: store!)
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
      "log_user_id": "\(idMap!.logUserID(userID: "foo"))",
      "user_id": "foo"
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
      "impression_id": "\(idMap!.impressionID(contentID: "foobar"))"
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
    XCTAssertTrue(message is Event_Click)
    let expectedJSON = """
    {
      "impression_id": "\(idMap!.impressionID(contentID: "foobar"))",
      "click_id": "fake-click-id",
      "name": "like",
      "target_url": "#like",
      "element_id": "like"
    }
    """
    XCTAssertEqual(try Event_Click(jsonString: expectedJSON),
                   message as! Event_Click)
  }

  func testLogClickToUnlike() {
    metricsLogger!.startSession(userID: "foo")
    let item = Item(contentID: "foobar")
    metricsLogger!.logClickToLike(content: item, didLike: false)
    let message = metricsLogger!.logMessages[0]
    XCTAssertTrue(message is Event_Click)
    let expectedJSON = """
    {
      "impression_id": "\(idMap!.impressionID(contentID: "foobar"))",
      "click_id": "fake-click-id",
      "name": "unlike",
      "target_url": "#unlike",
      "element_id": "unlike"
    }
    """
    XCTAssertEqual(try Event_Click(jsonString: expectedJSON),
                   message as! Event_Click)
  }
  
  func testLogClickToShowViewController() {
    metricsLogger!.startSession(userID: "foo")
    let viewController = FakeScreenViewController()
    let item = Item(contentID: "foobar")
    metricsLogger!.logClickToShow(viewController: viewController, forContent: item)
    let message = metricsLogger!.logMessages[0]
    XCTAssertTrue(message is Event_Click)
    let expectedJSON = """
    {
      "impression_id": "\(idMap!.impressionID(contentID: "foobar"))",
      "click_id": "fake-click-id",
      "name": "FakeScreen",
      "target_url": "#FakeScreen",
      "element_id": "FakeScreen"
    }
    """
    XCTAssertEqual(try Event_Click(jsonString: expectedJSON),
                   message as! Event_Click)
  }
  
  func testLogClickToSignUp() {
    metricsLogger!.logClickToSignUp(userID: "foo")
    let message = metricsLogger!.logMessages[0]
    XCTAssertTrue(message is Event_Click)
    let expectedJSON = """
    {
      "impression_id": "\(idMap!.impressionID(contentID: "foo"))",
      "click_id": "fake-click-id",
      "name": "sign-up",
      "target_url": "#sign-up",
      "element_id": "sign-up"
    }
    """
    XCTAssertEqual(try Event_Click(jsonString: expectedJSON),
                   message as! Event_Click)
  }
  
  func testLogClickToPurchase() {
    metricsLogger!.startSession(userID: "foo")
    let item = Item(contentID: "foobar")
    metricsLogger!.logClickToPurchase(item: item)
    let message = metricsLogger!.logMessages[0]
    XCTAssertTrue(message is Event_Click)
    let expectedJSON = """
    {
      "impression_id": "\(idMap!.impressionID(contentID: "foobar"))",
      "click_id": "fake-click-id",
      "name": "purchase",
      "target_url": "#purchase",
      "element_id": "purchase"
    }
    """
    XCTAssertEqual(try Event_Click(jsonString: expectedJSON),
                   message as! Event_Click)
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
      "name": "FakeScreen",
      "url": "#FakeScreen",
      "use_case": "SEARCH"
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

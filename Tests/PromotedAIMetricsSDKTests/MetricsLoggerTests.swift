import Foundation
import SwiftProtobuf
import TestHelpers
import XCTest

@testable import PromotedAIMetricsSDK
@testable import TestHelpers

final class MetricsLoggerTests: XCTestCase {
  
  private var config: ClientConfig?
  private var connection: FakeNetworkConnection?
  private var clock: FakeClock?
  private var store: FakePersistentStore?
  private var metricsLogger: MetricsLogger?

  public override func setUp() {
    super.setUp()
    config = ClientConfig()
    config!.metricsLoggingURL = "http://fake.promoted.ai/metrics"
    connection = FakeNetworkConnection()
    clock = FakeClock()
    store = FakePersistentStore()
    store!.userID = nil
    store!.logUserID = nil
    metricsLogger = MetricsLogger(messageProvider: FakeMessageProvider(),
                                  clientConfig: config!,
                                  clock: clock!,
                                  connection: connection!,
                                  idMap: SHA1IDMap.instance,
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
    let flushInterval = config!.batchLoggingFlushInterval
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
  
  static var allTests = [
    ("testStartSession", testStartSession),
    ("testStartSessionMultiple", testStartSessionMultiple),
    ("testStartSessionSignedOut", testStartSessionSignedOut),
    ("testStartSessionSignInThenSignOut", testStartSessionSignInThenSignOut),
    ("testStartSessionSignOutThenSignIn", testStartSessionSignOutThenSignIn),
    ("testBatchFlush", testBatchFlush),
  ]
}

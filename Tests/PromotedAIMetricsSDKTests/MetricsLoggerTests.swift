import Foundation
import XCTest

#if canImport(GTMSessionFetcherCore)
import GTMSessionFetcherCore
#elseif canImport(GTMSessionFetcher)
import GTMSessionFetcher
#else
#error("Can't import GTMSessionFetcher")
#endif

@testable import PromotedAIMetricsSDK

final class MetricsLoggerTests: XCTestCase {
  
  private var config: ClientConfig?
  private var fetcherService: GTMSessionFetcherService?
  private var clock: FakeClock?
  private var store: FakePersistentStore?
  private var metricsLogger: MetricsLogger?
  
  public override func setUp() {
    super.setUp()
    config = ClientConfig()
    fetcherService = GTMSessionFetcherService()
    clock = FakeClock()
    store = FakePersistentStore()
    store!.userID = nil
    store!.logUserID = nil
    metricsLogger = MetricsLogger(clientConfig: config!,
                                  fetcherService: fetcherService!,
                                  clock: clock!,
                                  store: store!)
  }
  
  func testStartSession() {
    metricsLogger!.startSession(userID: "foobar")
    XCTAssertEqual("foobar", store!.userID)
    XCTAssertNotNil(store!.logUserID)
  }
  
  func testStartSessionMultiple() {
    metricsLogger!.startSession(userID: "foobar")
    XCTAssertEqual("foobar", store!.userID)
    XCTAssertNotNil(store!.logUserID)
    
    let previousLogUserID = store!.logUserID
    metricsLogger!.startSession(userID: "foobar")
    XCTAssertEqual("foobar", store!.userID)
    XCTAssertEqual(previousLogUserID, store!.logUserID)
    
    metricsLogger!.startSession(userID: "foobarbaz")
    XCTAssertEqual("foobarbaz", store!.userID)
    XCTAssertNotNil(store!.logUserID)
    XCTAssertNotEqual(previousLogUserID, store!.logUserID)
  }
  
  func testStartSessionSignedOut() {
    metricsLogger!.startSessionSignedOut()
    XCTAssertNil(store!.userID)
    XCTAssertNotNil(store!.logUserID)
  }
  
  func testStartSessionSignInThenSignOut() {
    metricsLogger!.startSession(userID: "foobar")
    XCTAssertEqual("foobar", store!.userID)
    XCTAssertNotNil(store!.logUserID)
    
    let previousLogUserID = store!.logUserID
    metricsLogger!.startSessionSignedOut()
    XCTAssertNil(store!.userID)
    XCTAssertNotNil(store!.logUserID)
    XCTAssertNotEqual(previousLogUserID, store!.logUserID)
  }
  
  func testStartSessionSignOutThenSignIn() {
    metricsLogger!.startSessionSignedOut()
    XCTAssertNil(store!.userID)
    XCTAssertNotNil(store!.logUserID)
    
    let previousLogUserID = store!.logUserID
    metricsLogger!.startSession(userID: "foobar")
    XCTAssertEqual("foobar", store!.userID)
    XCTAssertNotNil(store!.logUserID)
    XCTAssertNotEqual(previousLogUserID, store!.logUserID)
  }
  
  static var allTests = [
    ("testStartSession", testStartSession),
    ("testStartSessionMultiple", testStartSessionMultiple),
    ("testStartSessionSignedOut", testStartSessionSignedOut),
    ("testStartSessionSignInThenSignOut", testStartSessionSignInThenSignOut),
    ("testStartSessionSignOutThenSignIn", testStartSessionSignOutThenSignIn),
  ]
}

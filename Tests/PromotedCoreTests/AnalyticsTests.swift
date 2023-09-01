import Foundation
import XCTest

@testable import PromotedCore
@testable import PromotedCoreTestHelpers

final class AnalyticsTests: ModuleTestCase {

  private var analytics: Analytics!
  private var metricsLogger: MetricsLogger!

  override func setUp() {
    super.setUp()
    module.clientConfig.metricsLoggingURL = "http://fake.promoted.ai/metrics"
    clock.advance(to: 123)
    store.userID = "foobar"
    store.anonUserID = "fake-anon-user-id"
    metricsLogger = MetricsLogger(deps: module)
    analytics = Analytics(deps: module)
  }

  func withMetricsLoggerBatch(batchError: Error? = nil,
                              batchResponseError: Error? = nil,
                              _ block: () -> Void) {
    analyticsConnection.reset()
    defer {
      if let batchError = batchError {
        connection.throwOnNextSendMessage = batchError
      }
      metricsLogger.flush()
      if let callback = connection.messages.last?.callback {
        if let batchResponseError = batchResponseError {
          callback(nil, batchResponseError)
        } else {
          callback(Data(), nil)
        }
      }
    }
    block()
  }

  func testLogBatch() {
    withMetricsLoggerBatch {
      metricsLogger.startSessionAndLogUser(userID: "foobar")
    }
    XCTAssertEqual(1, analyticsConnection.lastEventCount)
    XCTAssertGreaterThan(analyticsConnection.lastBytesSent, 0)
    XCTAssertEqual(0, analyticsConnection.lastErrors.count)

    withMetricsLoggerBatch {
      let item1 = Content(contentID: "hello", insertionID: "world")
      metricsLogger.logImpression(content: item1)
      let item2 = Content(contentID: "hippo", insertionID: "potamus")
      metricsLogger.logImpression(content: item2)
      metricsLogger.logAction(type: .purchase, content: item1)
    }
    XCTAssertEqual(3, analyticsConnection.lastEventCount)
    XCTAssertGreaterThan(analyticsConnection.lastBytesSent, 0)
    XCTAssertEqual(0, analyticsConnection.lastErrors.count)
  }

  func testLogFunctionError() {
    let error = NSError(domain: "ai.promoted", code: -1, userInfo: nil)
    withMetricsLoggerBatch {
      metricsLogger.startSessionAndLogUser(userID: "foobar")
      module.operationMonitor.execute(function: "foo") {
        module.operationMonitor.executionDidError(error)
      }
    }
    XCTAssertEqual(1, analyticsConnection.lastEventCount)
    XCTAssertGreaterThan(analyticsConnection.lastBytesSent, 0)
    XCTAssertEqual([error], analyticsConnection.lastErrors as [NSError])
  }

  func testLogBatchError() {
    let error = NSError(domain: "ai.promoted", code: -1, userInfo: nil)
    withMetricsLoggerBatch(batchError: error) {
      let item1 = Content(contentID: "hello", insertionID: "world")
      metricsLogger.logImpression(content: item1)
    }
    XCTAssertEqual(0, analyticsConnection.lastEventCount)
    XCTAssertEqual(0, analyticsConnection.lastBytesSent)
    XCTAssertEqual([error], analyticsConnection.lastErrors as [NSError])
  }

  func testLogBatchResponseError() {
    let error = NSError(domain: "ai.promoted", code: -1, userInfo: nil)
    withMetricsLoggerBatch(batchResponseError: error) {
      let item1 = Content(contentID: "hello", insertionID: "world")
      metricsLogger.logImpression(content: item1)
    }
    XCTAssertEqual(0, analyticsConnection.lastEventCount)
    XCTAssertEqual(0, analyticsConnection.lastBytesSent)
    XCTAssertEqual([error], analyticsConnection.lastErrors as [NSError])
  }
}

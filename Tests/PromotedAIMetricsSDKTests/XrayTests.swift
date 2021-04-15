import Foundation
import TestHelpers
import XCTest

@testable import PromotedAIMetricsSDK

final class XrayTests: XCTestCase {
  
  private var clock: FakeClock?
  private var config: ClientConfig?
  private var xray: Xray?
  
  override func setUp() {
    super.setUp()
    clock = FakeClock()
    config = ClientConfig()
    xray = Xray(clock: clock!, config: config!)
  }
  
  func testSingleBatch() {
    clock!.advance(toMillis: 0)
    xray!.callWillStart(context: .logAction)
    var action = Event_Action()
    action.actionID = "fake-action-id"
    xray!.callDidLog(message: action)
    clock!.advance(toMillis: 123)
    xray!.callDidComplete()
    
    clock!.advance(toMillis: 200)
    xray!.callWillStart(context: .logImpression)
    var impression = Event_Impression()
    impression.impressionID = "fake-impression-id"
    xray!.callDidLog(message: impression)
    clock!.advance(toMillis: 250)
    xray!.callDidComplete()
    
    clock!.advance(toMillis: 456)
    xray!.metricsLoggerBatchWillStart()
    var logRequest = Event_LogRequest()
    logRequest.action.append(action)
    xray!.metricsLoggerBatchWillSend(message: logRequest)
    clock!.advance(toMillis: 789)
    xray!.metricsLoggerBatchDidComplete()
    clock!.advance(toMillis: 1234)
    xray!.metricsLoggerBatchResponseDidComplete()

    let networkTime: TimeIntervalMillis = 1234
    let batchTime: TimeIntervalMillis = 789 - 456
    let callTime: TimeIntervalMillis = 123 + 50
    let acrossTime = batchTime + callTime
    
    XCTAssertGreaterThan(xray!.totalBytesSent, 0)
    XCTAssertEqual(1, xray!.totalRequestsMade)
    XCTAssertEqual(acrossTime, xray!.totalTimeSpent)
    
    XCTAssertEqual(1, xray!.networkBatches.count)
    let batch = xray!.networkBatches[0]
    XCTAssertGreaterThan(batch.messageSizeBytes, 0)
    XCTAssertEqual(networkTime, batch.networkEndTime)
    XCTAssertEqual(acrossTime, batch.timeSpentAcrossCalls)
    XCTAssertEqual(2, batch.calls.count)

    let call1 = batch.calls[0]
    XCTAssertEqual(0, call1.callStack.count)
    XCTAssertEqual(0, call1.startTime)
    XCTAssertEqual(123, call1.endTime)
    XCTAssertEqual(.logAction, call1.context)
    XCTAssertEqual(123, call1.timeSpent)
    XCTAssertEqual(action, call1.messages[0] as! Event_Action)
    
    let call2 = batch.calls[1]
    XCTAssertEqual(0, call2.callStack.count)
    XCTAssertEqual(200, call2.startTime)
    XCTAssertEqual(250, call2.endTime)
    XCTAssertEqual(.logImpression, call2.context)
    XCTAssertEqual(50, call2.timeSpent)
    XCTAssertEqual(impression, call2.messages[0] as! Event_Impression)
  }
  
  // TODO(yu-hong): More tests.
}

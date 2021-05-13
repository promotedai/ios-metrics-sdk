import Foundation
import XCTest

@testable import PromotedCore
@testable import PromotedCoreTestHelpers

final class XrayTests: ModuleTestCase {
  
  private var xray: Xray!
  
  typealias Context = OperationMonitor.Context
  
  override func setUp() {
    super.setUp()
    xray = Xray(deps: module)
  }
  
  func testSingleBatch() {
    clock.advance(toMillis: 0)
    let actionContext = Context.function("logAction")
    xray.executionWillStart(context: actionContext)
    var action = Event_Action()
    action.actionID = "fake-action-id"
    xray.execution(context: actionContext, willLogMessage: action)
    clock.advance(toMillis: 123)
    xray.executionDidEnd(context: actionContext)
    
    clock.advance(toMillis: 200)
    let impressionContext = Context.function("logImpression")
    xray.executionWillStart(context: impressionContext)
    var impression = Event_Impression()
    impression.impressionID = "fake-impression-id"
    xray.execution(context: impressionContext, willLogMessage: impression)
    clock.advance(toMillis: 250)
    xray.executionDidEnd(context: impressionContext)
    
    clock.advance(toMillis: 456)
    xray.executionWillStart(context: .batch)
    var logRequest = Event_LogRequest()
    logRequest.action.append(action)
    xray.execution(context: .batch, willLogMessage: logRequest)
    let data = "fake http body".data(using: .utf8)!
    xray.execution(context: .batch, willLogData: data)
    clock.advance(toMillis: 789)
    xray.executionDidEnd(context: .batch)
    clock.advance(toMillis: 1234)
    xray.executionWillStart(context: .batchResponse)
    xray.executionDidLog(context: .batchResponse)
    xray.execution(context: .batch, willLogData: data)
    xray.executionDidEnd(context: .batchResponse)

    let networkTime: TimeIntervalMillis = 1234
    let batchTime: TimeIntervalMillis = 789 - 456
    let callTime: TimeIntervalMillis = 123 + 50
    let acrossTime = batchTime + callTime
    
    XCTAssertGreaterThan(xray.totalBytesSent, 0)
    XCTAssertEqual(1, xray.totalRequestsMade)
    XCTAssertEqual(acrossTime, xray.totalTimeSpent.millis)
    
    XCTAssertEqual(1, xray.networkBatches.count)
    let batch = xray.networkBatches[0]
    XCTAssertGreaterThan(batch.messageSizeBytes, 0)
    XCTAssertEqual(networkTime, batch.networkEndTime.millis)
    XCTAssertEqual(acrossTime, batch.timeSpentAcrossCalls.millis)
    XCTAssertEqual(2, batch.calls.count)

    let call1 = batch.calls[0]
    XCTAssertEqual(0, call1.callStack.count)
    XCTAssertEqual(0, call1.startTime.millis)
    XCTAssertEqual(123, call1.endTime.millis)
    XCTAssertEqual("logAction", call1.context)
    XCTAssertEqual(123, call1.timeSpent.millis)
    XCTAssertEqual(action, call1.messages[0] as! Event_Action)
    
    let call2 = batch.calls[1]
    XCTAssertEqual(0, call2.callStack.count)
    XCTAssertEqual(200, call2.startTime.millis)
    XCTAssertEqual(250, call2.endTime.millis)
    XCTAssertEqual("logImpression", call2.context)
    XCTAssertEqual(50, call2.timeSpent.millis)
    XCTAssertEqual(impression, call2.messages[0] as! Event_Impression)
  }
  
  func testCalls() {

    func callXray(_ function: String) -> Context {
      let context = Context.function(function)
      xray.executionWillStart(context: context)
      xray.executionDidEnd(context: context)
      return context
    }

    func batchXray(_ functions: [String]) -> [Context] {
      let allCalls = functions.map { callXray($0) }
      xray.executionWillStart(context: .batch)
      xray.executionDidEnd(context: .batch)
      xray.executionWillStart(context: .batchResponse)
      xray.executionDidEnd(context: .batchResponse)
      return allCalls
    }

    var allCalls = [Context]()
    allCalls.append(contentsOf: batchXray(["hello", "world"]))
    allCalls.append(contentsOf: batchXray(["hello", "darkness"]))
    allCalls.append(contentsOf: batchXray(["my", "old", "friend"]))

    XCTAssertEqual(allCalls.map(\.debugDescription),
                   xray.calls.map(\.context))
  }
  
  func testErrors() {
    
    func batchXray(batchError: Error? = nil,
                   batchResponseError: Error? = nil) {
      xray.executionWillStart(context: .batch)
      if let e = batchError {
        xray.execution(context: .batch, didError: e)
      }
      xray.executionDidEnd(context: .batch)
      xray.executionWillStart(context: .batchResponse)
      if let e = batchResponseError {
        xray.execution(context: .batchResponse, didError: e)
      } else {
        xray.executionDidLog(context: .batchResponse)
      }
      xray.executionDidEnd(context: .batchResponse)
    }

    let context1 = Context.function("f1")
    let error1 = NSError(domain: "ai.promoted", code: -1, userInfo: nil)
    xray.executionWillStart(context: context1)
    xray.execution(context: context1, didError: error1)
    xray.executionDidEnd(context: context1)

    batchXray()

    let context2 = Context.function("f2")
    let error2 = NSError(domain: "ai.promoted", code: -2, userInfo: nil)
    xray.executionWillStart(context: context2)
    xray.execution(context: context2, didError: error2)
    xray.executionDidEnd(context: context2)

    let error3 = NSError(domain: "ai.promoted", code: -3, userInfo: nil)
    batchXray(batchError: error3)

    let context3 = Context.function("f3")
    xray.executionWillStart(context: context3)
    xray.executionDidEnd(context: context3)

    let error4 = NSError(domain: "ai.promoted", code: -4, userInfo: nil)
    batchXray(batchResponseError: error4)

    let expected = [error1, error2, error3, error4]
    XCTAssertEqual(expected, xray.errors as [NSError])
  }
}

import Foundation
import SwiftProtobuf
import XCTest

@testable import PromotedCore

final class OperationMonitorTests: XCTestCase {
  
  class Listener: OperationMonitorListener {
    var starts: [String] = []
    var ends: [String] = []
    var errors: [(String, Error)] = []
    var data: [(String, Data)] = []

    func executionWillStart(context: Context) {
      starts.append(context.debugDescription)
    }

    func executionDidEnd(context: Context) {
      ends.append(context.debugDescription)
    }

    func execution(context: Context, didError error: Error) {
      errors.append((context.debugDescription, error))
    }

    func execution(context: Context, willLogData data: Data) {
      data.append((context.debugDescription, data))
    }
  }
  
  private var listener: Listener!
  private var monitor: OperationMonitor!
  
  override func setUp() {
    super.setUp()
    listener = Listener()
    monitor = OperationMonitor()
    monitor.addOperationMonitorListener(listener)
  }
  
  func testStartExecute() {
    monitor.execute {
      XCTAssertEqual([#function], listener.starts)
      XCTAssertEqual([], listener.ends)
    }
    XCTAssertEqual([#function], listener.starts)
    XCTAssertEqual([#function], listener.ends)
  }
  
  func testNestedExecute() {
    monitor.execute(function: "outer") {
      XCTAssertEqual(["outer"], listener.starts)
      XCTAssertEqual([], listener.ends)
      monitor.execute(function: "inner1") {
        XCTAssertEqual(["outer"], listener.starts)
        XCTAssertEqual([], listener.ends)
      }
      monitor.execute(function: "inner2") {
        XCTAssertEqual(["outer"], listener.starts)
        XCTAssertEqual([], listener.ends)
      }
    }
    XCTAssertEqual(["outer"], listener.starts)
    XCTAssertEqual(["outer"], listener.ends)
  }
  
  func testLoggingActivityAndErrors() {
    let error1 = NSError(domain: "ai.promoted", code: -1, userInfo: nil)
    let error2 = NSError(domain: "ai.promoted", code: -2, userInfo: nil)
    let data = "I am the very model of a modern hippopotamus".data(using: .utf8)!
    monitor.execute(function: "outer") {
      monitor.executionDidError(error1)
      monitor.execute(function: "inner1") {
        monitor.executionDidError(error2)
      }
      monitor.execute(function: "inner2") {
        monitor.executionWillLog(data: data)
      }
    }
    let actualErrors = listener.errors
    XCTAssertEqual(["outer", "outer"], actualErrors.map(\.0))
    XCTAssertEqual(error1, actualErrors[0].1 as NSError)
    XCTAssertEqual(error2, actualErrors[1].1 as NSError)
    let actualData = listener.data
    XCTAssertEqual(["outer"], actualData.map(\.0))
    XCTAssertEqual([data], actualData.map(\.1))
  }
}

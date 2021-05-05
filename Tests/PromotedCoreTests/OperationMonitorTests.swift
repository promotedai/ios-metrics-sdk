import Foundation
import XCTest

@testable import PromotedCore

final class OperationMonitorTests: XCTestCase {
  
  class Listener: OperationMonitorListener {
    var starts: [String] = []
    var ends: [String] = []

    func executionWillStart(context: String) {
      starts.append(context)
    }
    
    func executionDidEnd(context: String) {
      ends.append(context)
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
    monitor.execute(context: "outer") {
      XCTAssertEqual(["outer"], listener.starts)
      XCTAssertEqual([], listener.ends)
      monitor.execute(context: "inner1") {
        XCTAssertEqual(["outer"], listener.starts)
        XCTAssertEqual([], listener.ends)
      }
      monitor.execute(context: "inner2") {
        XCTAssertEqual(["outer"], listener.starts)
        XCTAssertEqual([], listener.ends)
      }
    }
    XCTAssertEqual(["outer"], listener.starts)
    XCTAssertEqual(["outer"], listener.ends)
  }
}

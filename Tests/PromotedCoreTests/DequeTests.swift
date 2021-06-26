import Foundation
import XCTest

@testable import PromotedCore

final class DequeTests: XCTestCase {

  func testNoMaximumSize() {
    var deque: Deque<Int> = [1, 2, 3, 4, 5]
    XCTAssertEqual([1, 2, 3, 4, 5], deque.values)
    deque.pushFront(0)
    XCTAssertEqual([0, 1, 2, 3, 4, 5], deque.values)
    deque.pushBack(6)
    XCTAssertEqual([0, 1, 2, 3, 4, 5, 6], deque.values)
    deque.pushFront(contentsOf: [-2, -1])
    XCTAssertEqual([-2, -1, 0, 1, 2, 3, 4, 5, 6], deque.values)
    deque.pushBack(contentsOf: [7, 8])
    XCTAssertEqual([-2, -1, 0, 1, 2, 3, 4, 5, 6, 7, 8], deque.values)
    XCTAssertEqual(8, deque.popBack())
    XCTAssertEqual([-2, -1, 0, 1, 2, 3, 4, 5, 6, 7], deque.values)
    deque.popBack(5)
    XCTAssertEqual([-2, -1, 0, 1, 2], deque.values)
    XCTAssertEqual(-2, deque.popFront())
    XCTAssertEqual([-1, 0, 1, 2], deque.values)
    deque.popFront(3)
    XCTAssertEqual([2], deque.values)
  }

  func testPushBackWithMaximumSize() {
    var deque: Deque<Int> = [1, 2, 3, 4, 5]
    deque.maximumSize = 5
    deque.pushBack(6)
    XCTAssertEqual([2, 3, 4, 5, 6], deque.values)
    deque.pushBack(contentsOf: [7, 8, 9])
    XCTAssertEqual([5, 6, 7, 8, 9], deque.values)
    deque.pushBack(contentsOf: [10, 11, 12, 13, 14, 15, 16])
    XCTAssertEqual([12, 13, 14, 15, 16], deque.values)
  }

  func testPushFrontWithMaximumSize() {
    var deque: Deque<Int> = [1, 2, 3, 4, 5]
    deque.maximumSize = 5
    deque.pushFront(0)
    XCTAssertEqual([0, 1, 2, 3, 4], deque.values)
    deque.pushFront(contentsOf: [-2, -1])
    XCTAssertEqual([-2, -1, 0, 1, 2], deque.values)
    deque.pushFront(contentsOf: [10, 11, 12, 13, 14, 15, 16])
    XCTAssertEqual([10, 11, 12, 13, 14], deque.values)
  }

  func testSetMaximumSize() {
    var deque: Deque<Int> = [1, 2, 3, 4, 5]
    deque.maximumSize = 3
    XCTAssertEqual([3, 4, 5], deque.values)
  }
}

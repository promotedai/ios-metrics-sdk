import Foundation
import XCTest

@testable import PromotedCore
@testable import PromotedCoreTestHelpers

final class IDProducerTests: XCTestCase {

  private var idProducer: IDProducer!

  override func setUp() {
    super.setUp()
    let idMap = FakeIDMap()
    idMap.incrementCounts = true
    idProducer = IDProducer(initialValueProducer: { "initial-id" },
                            nextValueProducer: { idMap.actionID() })
  }

  func testInitialValue() {
    XCTAssertEqual("initial-id", idProducer.currentOrPendingValue)
    XCTAssertNil(idProducer.currentValue)
  }

  func testNextValue() {
    XCTAssertEqual("initial-id", idProducer.currentOrPendingValue)

    // First call to advance() should use initial value.
    XCTAssertEqual("initial-id", idProducer.advance())
    XCTAssertEqual("initial-id", idProducer.currentValue)

    // Subsequent calls to advance() should advance id.
    XCTAssertEqual("fake-action-id-1", idProducer.advance())
    XCTAssertEqual("fake-action-id-1", idProducer.currentValue)
    XCTAssertEqual("fake-action-id-2", idProducer.advance())
    XCTAssertEqual("fake-action-id-2", idProducer.currentValue)
  }

  func testCustomValues() {
    XCTAssertEqual("initial-id", idProducer.currentOrPendingValue)
    XCTAssertNil(idProducer.currentValue)

    // Custom values should be ancestor IDs immediately.
    idProducer.currentValue = "my-custom-value"
    XCTAssertEqual("my-custom-value", idProducer.currentOrPendingValue)
    XCTAssertEqual("my-custom-value", idProducer.currentValue)

    idProducer.currentValue = "my-new-value"
    XCTAssertEqual("my-new-value", idProducer.currentOrPendingValue)
    XCTAssertEqual("my-new-value", idProducer.currentValue)

    // Calls to advance() should drop custom values.
    XCTAssertEqual("fake-action-id-1", idProducer.advance())
    XCTAssertEqual("fake-action-id-1", idProducer.currentOrPendingValue)
    XCTAssertEqual("fake-action-id-1", idProducer.currentValue)

    // A new custom value should override internal value.
    idProducer.currentValue = "my-custom-value"
    XCTAssertEqual("my-custom-value", idProducer.currentOrPendingValue)
    XCTAssertEqual("my-custom-value", idProducer.currentValue)
  }

  func testNilCustomValue() {
    // Setting an explicit nil value should cause the pending
    // value to return nil (and not initial value).
    idProducer.currentValue = nil
    XCTAssertNil(idProducer.currentValue)
    XCTAssertNil(idProducer.currentOrPendingValue)
  }

  func testReset() {
    idProducer.currentValue = "my-custom-value"
    idProducer.reset()
    XCTAssertNil(idProducer.currentValue)
    XCTAssertEqual("initial-id", idProducer.currentOrPendingValue)
  }
}

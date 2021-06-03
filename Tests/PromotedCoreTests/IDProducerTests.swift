import Foundation
import XCTest

@testable import PromotedCore
@testable import PromotedCoreTestHelpers

final class IDProducerTests: XCTestCase {

  private var idProducer: IDProducer!
  private var idCount: Int = 0

  override func setUp() {
    super.setUp()
    let idMap = FakeIDMap()
    idMap.incrementCounts = true
    idProducer = IDProducer(initialValueProducer: { "initial-id" },
                            nextValueProducer: { idMap.actionID() })
  }

  func testInitialValue() {
    XCTAssertEqual("initial-id", idProducer.currentValue)
  }

  func testCurrentValue() {
    XCTAssertEqual("initial-id", idProducer.currentValue)
    XCTAssertNil(idProducer.currentValueAsAncestorID)
    idProducer.nextValue()
    XCTAssertEqual("initial-id", idProducer.currentValue)
    XCTAssertEqual("initial-id", idProducer.currentValueAsAncestorID)
  }

  func testNextValue() {
    XCTAssertEqual("initial-id", idProducer.currentValue)

    // First call to nextValue() should use initial value.
    XCTAssertEqual("initial-id", idProducer.nextValue())
    XCTAssertEqual("initial-id", idProducer.currentValue)

    // Subsequent calls to nextValue() should advance id.
    XCTAssertEqual("fake-action-id-1", idProducer.nextValue())
    XCTAssertEqual("fake-action-id-1", idProducer.currentValue)
    XCTAssertEqual("fake-action-id-2", idProducer.nextValue())
    XCTAssertEqual("fake-action-id-2", idProducer.currentValue)
  }

  func testCustomValues() {
    XCTAssertEqual("initial-id", idProducer.currentValue)
    XCTAssertNil(idProducer.currentValueAsAncestorID)

    // Custom values should be ancestor IDs immediately.
    idProducer.currentValue = "my-custom-value"
    XCTAssertEqual("my-custom-value", idProducer.currentValue)
    XCTAssertEqual("my-custom-value", idProducer.currentValueAsAncestorID)

    idProducer.currentValue = "my-new-value"
    XCTAssertEqual("my-new-value", idProducer.currentValue)
    XCTAssertEqual("my-new-value", idProducer.currentValueAsAncestorID)

    // Calls to nextValue() should drop custom values.
    XCTAssertEqual("fake-action-id-1", idProducer.nextValue())
    XCTAssertEqual("fake-action-id-1", idProducer.currentValue)

    // A new custom value should override internal value.
    idProducer.currentValue = "my-custom-value"
    XCTAssertEqual("my-custom-value", idProducer.currentValue)
    XCTAssertEqual("my-custom-value", idProducer.currentValueAsAncestorID)
  }
}

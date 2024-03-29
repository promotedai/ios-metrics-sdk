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
    idProducer = IDProducer(
      initialValueProducer: { .autogenerated(value: "initial-id") },
      nextValueProducer: { idMap.actionID() }
    )
  }

  func testInitialValue() {
    XCTAssertEqual(
      .autogenerated(value: "initial-id"),
      idProducer.currentOrPendingValue
    )
    XCTAssertEqual(.null, idProducer.currentValue)
  }

  func testNextValue() {
    XCTAssertEqual(
      .autogenerated(value: "initial-id"),
      idProducer.currentOrPendingValue
    )

    // First call to advance() should use initial value.
    XCTAssertEqual(
      .autogenerated(value: "initial-id"),
      idProducer.advance()
    )
    XCTAssertEqual(
      .autogenerated(value: "initial-id"),
      idProducer.currentValue
    )

    // Subsequent calls to advance() should advance id.
    XCTAssertEqual(
      .autogenerated(value: "fake-action-id-1"),
      idProducer.advance()
    )
    XCTAssertEqual(
      .autogenerated(value: "fake-action-id-1"),
      idProducer.currentValue
    )
    XCTAssertEqual(
      .autogenerated(value: "fake-action-id-2"),
      idProducer.advance()
    )
    XCTAssertEqual(
      .autogenerated(value: "fake-action-id-2"),
      idProducer.currentValue
    )
  }

  func testCustomValues() {
    XCTAssertEqual(
      .autogenerated(value: "initial-id"),
      idProducer.currentOrPendingValue
    )
    XCTAssertEqual(.null, idProducer.currentValue)

    // Custom values should be ancestor IDs immediately.
    idProducer.currentValue = .platformSpecified(value: "my-custom-value")
    XCTAssertEqual(
      .platformSpecified(value: "my-custom-value"),
      idProducer.currentOrPendingValue
    )
    XCTAssertEqual(
      .platformSpecified(value: "my-custom-value"),
      idProducer.currentValue
    )

    idProducer.currentValue = .platformSpecified(value: "my-new-value")
    XCTAssertEqual(
      .platformSpecified(value: "my-new-value"),
      idProducer.currentOrPendingValue
    )
    XCTAssertEqual(
      .platformSpecified(value: "my-new-value"),
      idProducer.currentValue
    )

    // Calls to advance() should drop custom values.
    XCTAssertEqual(
      .autogenerated(value: "fake-action-id-1"),
      idProducer.advance()
    )
    XCTAssertEqual(
      .autogenerated(value: "fake-action-id-1"),
      idProducer.currentOrPendingValue
    )
    XCTAssertEqual(
      .autogenerated(value: "fake-action-id-1"),
      idProducer.currentValue
    )

    // A new custom value should override internal value.
    idProducer.currentValue = .platformSpecified(value: "my-custom-value")
    XCTAssertEqual(
      .platformSpecified(value: "my-custom-value"),
      idProducer.currentOrPendingValue
    )
    XCTAssertEqual(
      .platformSpecified(value: "my-custom-value"),
      idProducer.currentValue
    )
  }

  func testNilCustomValue() {
    // Setting an explicit nil value should cause the pending
    // value to return nil (and not initial value).
    idProducer.currentValue = .null
    XCTAssertEqual(.null, idProducer.currentValue)
    XCTAssertEqual(.null, idProducer.currentOrPendingValue)
  }

  func testReset() {
    idProducer.currentValue = .platformSpecified(value: "my-custom-value")
    idProducer.reset()
    XCTAssertEqual(.null, idProducer.currentValue)
    XCTAssertEqual(
      .autogenerated(value: "initial-id"),
      idProducer.currentOrPendingValue
    )
  }
}

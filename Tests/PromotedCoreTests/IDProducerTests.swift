import Foundation
import XCTest

@testable import PromotedCore

final class IDProducerTests: XCTestCase {

  private var idProducer: IDProducer!
  private var idCount: Int = 0

  override func setUp() {
    super.setUp()
    idCount = 0
    idProducer = IDProducer(initialValueProducer: {
      return "initial-id"
    }, nextValueProducer: {
      [weak self] in
      guard let self = self else { return "error" }
      self.idCount += 1
      return "id-\(self.idCount)"
    })
  }

  func testInitialValue() {
    XCTAssertEqual("initial-id", idProducer.currentValue)
  }

  func testCurrentValue() {
    XCTAssertEqual("initial-id", idProducer.currentValue)
    XCTAssertNil(idProducer.currentValueForAncestorID)
    idProducer.nextValue()
    XCTAssertEqual("initial-id", idProducer.currentValue)
    XCTAssertEqual("initial-id", idProducer.currentValueForAncestorID)
  }

  func testNextValue() {
    XCTAssertEqual("initial-id", idProducer.currentValue)

    // First call to nextValue() should use initial value.
    XCTAssertEqual("initial-id", idProducer.nextValue())
    XCTAssertEqual("initial-id", idProducer.currentValue)

    // Subsequent calls to nextValue() should advance id.
    XCTAssertEqual("id-1", idProducer.nextValue())
    XCTAssertEqual("id-1", idProducer.currentValue)
    XCTAssertEqual("id-2", idProducer.nextValue())
    XCTAssertEqual("id-2", idProducer.currentValue)
  }
}

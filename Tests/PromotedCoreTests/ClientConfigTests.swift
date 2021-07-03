import Foundation
import XCTest

@testable import PromotedCore

final class ClientConfigTests: XCTestCase {

  func testBound() {
    let config = ClientConfig()
    config.disableAssertInValidationForTesting()
    config.loggingFlushInterval = -1.0
    XCTAssertEqual(1.0, config.loggingFlushInterval, accuracy: 0.001)
  }

  func testBadEnumValues() {
    let config = ClientConfig()
    config.disableAssertInValidationForTesting()

    config.metricsLoggingWireFormat = .unknown
    XCTAssertEqual(.binary, config.metricsLoggingWireFormat)

    config.xrayLevel = .unknown
    XCTAssertEqual(.none, config.xrayLevel)

    config.osLogLevel = .unknown
    XCTAssertEqual(.none, config.osLogLevel)

    // Use ObjC key-value coding to force invalid enum values.
    // You should never do this normally.
    config.setValue("invalid", forKey: "metricsLoggingWireFormat")
    XCTAssertEqual(.binary, config.metricsLoggingWireFormat)

    config.setValue("invalid", forKey: "xrayLevel")
    XCTAssertEqual(.none, config.xrayLevel)

    config.setValue("invalid", forKey: "osLogLevel")
    XCTAssertEqual(.none, config.osLogLevel)
  }
}

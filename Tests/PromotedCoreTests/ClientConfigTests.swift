import Foundation
import XCTest

@testable import PromotedCore

final class ClientConfigTests: XCTestCase {

  func testValue() {
    let config = ClientConfig()
    let mirror = Mirror(reflecting: config)
    for child in mirror.children {
      guard let name = child.label else {
        XCTFail("Child with no label: \(String(describing: child))")
        return
      }
      _ = config.value(forName: name)
    }
  }

  func testSetValue() {
    var config = ClientConfig()
    let mirror = Mirror(reflecting: config)
    for child in mirror.children {
      guard let name = child.label else {
        XCTFail("Child with no label: \(String(describing: child))")
        return
      }
      config.setValue(child.value, forName: name)
    }
  }

  func testBound() {
    var config = ClientConfig()
    config.disableAssertInValidationForTesting()
    config.loggingFlushInterval = -1.0
    XCTAssertEqual(1.0, config.loggingFlushInterval, accuracy: 0.001)
  }

  func testBadEnumValues() {
    var config = ClientConfig()
    config.disableAssertInValidationForTesting()

    config.setValue("invalid", forName: "metricsLoggingWireFormat")
    XCTAssertEqual(.binary, config.metricsLoggingWireFormat)

    config.setValue("invalid", forName: "xrayLevel")
    XCTAssertEqual(.none, config.xrayLevel)

    config.setValue("invalid", forName: "osLogLevel")
    XCTAssertEqual(.none, config.osLogLevel)
  }
}

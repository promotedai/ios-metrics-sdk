import Foundation
import XCTest

@testable import PromotedCore

final class ClientConfigTests: XCTestCase {

  func testValue() {
    var config = ClientConfig()
    config.disableAssertInValidationForTesting()
    let mirror = Mirror(reflecting: config)
    for child in mirror.children {
      guard let name = child.label else {
        XCTFail("Child with no label: \(String(describing: child))")
        return
      }
      if name == "assertInValidation" { continue }
      XCTAssertNotNil(config.value(forKey: name))
    }
  }

  func testSetValue() {
    var config = ClientConfig()
    // Don't call config.disableAssertInValidationForTesting().
    // If this test trips the assert, you need to add support
    // for your new property in value()/setValue().
    let mirror = Mirror(reflecting: config)
    for child in mirror.children {
      guard let name = child.label else {
        XCTFail("Child with no label: \(String(describing: child))")
        return
      }
      if name == "assertInValidation" { continue }
      config.setValue(child.value, forKey: name)
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

    config.setValue("invalid", forKey: "metricsLoggingWireFormat")
    XCTAssertEqual(.binary, config.metricsLoggingWireFormat)

    config.setValue("invalid", forKey: "xrayLevel")
    XCTAssertEqual(.none, config.xrayLevel)

    config.setValue("invalid", forKey: "osLogLevel")
    XCTAssertEqual(.none, config.osLogLevel)
  }

  func testObjCFields() {
    let swiftConfig = ClientConfig()
    let swiftKeyToType = Mirror(reflecting: swiftConfig)
      .children
      .filter { $0.label != "assertInValidation" }
      .reduce(into: [String: String]()) {
        $0[$1.label!] = String(describing: type(of: $1.value))
      }

    let objcConfig = _ObjCClientConfig()
    let objcKeyToType = Mirror(reflecting: objcConfig)
      .children
      .reduce(into: [String: String]()) {
        $0[$1.label!] = String(describing: type(of: $1.value))
      }

    XCTAssertEqual(swiftKeyToType, objcKeyToType)
  }
}

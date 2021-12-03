import Foundation
import XCTest

@testable import PromotedCore

final class IOSBuildInfoTests: XCTestCase {

  func assert(string: String, matchesRegex regex: String) {
    XCTAssertFalse(string.isEmpty)
    guard let range = string.range(
      of: regex,
      options: .regularExpression
    ) else {
      XCTFail(
        "'\(string)' does not match regex '\(regex)'"
      )
      return
    }
    XCTAssertEqual(string.startIndex ..< string.endIndex, range)
  }

  func testPlatformAppVersionSwiftPM() {
    let build = IOSBuildInfo()
    let version = build.platformAppVersion
    let parts = version.split(separator: " ").map { String($0) }
    XCTAssertEqual(3, parts.count)
    XCTAssertNotEqual("Unknown", parts[0])
    assert(string: parts[0], matchesRegex: #"\d+\.\d+"#)
    XCTAssertEqual("build", parts[1])
    // Github Actions sometimes return "Unknown" in tests.
    if parts[2] != "Unknown" {
      assert(string: parts[2], matchesRegex: #"\d+"#)
    }
  }

  func testPromotedMobileSDKVersionSwiftPM() {
    let build = IOSBuildInfo()
    let version = build.promotedMobileSDKVersion
    XCTAssertNotEqual("Unknown", version)
    assert(string: version, matchesRegex: #"\d+\.\d+\.\d+"#)
  }
}

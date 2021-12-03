import Foundation
import XCTest

@testable import PromotedCore

final class IOSBuildInfoTests: XCTestCase {

  func assert(string: String, matchesRegex regex: String) {
    XCTAssertNotEqual("Unknown", string)
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
    let parts = version.split(separator: " ")
    XCTAssertEqual(3, parts.count)
    assert(string: String(parts[0]), matchesRegex: #"\d+\.\d+"#)
    XCTAssertEqual("build", parts[1])
    assert(string: String(parts[2]), matchesRegex: #"\d+"#)
  }

  func testPromotedMobileSDKVersionSwiftPM() {
    let build = IOSBuildInfo()
    let version = build.promotedMobileSDKVersion
    assert(string: version, matchesRegex: #"\d+\.\d+\.\d+"#)
  }
}

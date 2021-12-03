import Foundation
import XCTest

@testable import PromotedCore

final class IOSBuildInfoTests: XCTestCase {

  func assert(regex: String, matches string: String) {
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
    assert(regex: #"\d+\.\d+"#, matches: parts[0])
    XCTAssertEqual("build", parts[1])
    // Github Actions sometimes return "Unknown" in tests.
    if parts[2] != "Unknown" {
      assert(regex: #"\d+"#, matches: parts[2])
    }
  }

  func testPromotedMobileSDKVersionSwiftPM() {
    let build = IOSBuildInfo()
    let version = build.promotedMobileSDKVersion
    XCTAssertNotEqual("Unknown", version)
    assert(regex: #"\d+\.\d+\.\d+"#, matches: version)
  }
}

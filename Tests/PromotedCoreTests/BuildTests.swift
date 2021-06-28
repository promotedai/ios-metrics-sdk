import Foundation
import XCTest

@testable import PromotedCore

final class BuildTests: XCTestCase {

  func testLibVersionSwiftPM() {
    let version = Build.libVersion
    XCTAssertNotEqual("Unknown", version)
    XCTAssertFalse(version.isEmpty)
    guard let range = version.range(of: #"\d+\.\d+\.\d+"#, options: .regularExpression) else {
      XCTFail("Version string \(version) does not match x.y.z")
      return
    }
    XCTAssertEqual(version.startIndex ..< version.endIndex, range)
  }
}

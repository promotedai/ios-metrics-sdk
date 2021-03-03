import Foundation
import XCTest

@testable import PromotedAIMetricsSDK

final class SHA1IDMapTests: XCTestCase {

  private var map: IDMap?
  
  private static let testBits = 16

  public override func setUp() {
    super.setUp()
    map = SHA1IDMap.instance
  }
  
  private func iterateStrings(block: (String) -> Void) {
    for i in 0 ..< (1 << SHA1IDMapTests.testBits) {
      let str = String(format: "%02x", i)
      block(str)
    }
  }
  
  func testUniqueness() {
    var idsSeen = [String: String]()
    iterateStrings { str in
      let id = map!.deterministicUUIDString(value: str)
      if let usedID = idsSeen[id] {
        XCTFail("\(str): hash \(id) already seen for \(usedID)");
        return
      }
      idsSeen[id] = str
    }
  }
  
  func testDeterminism() {
    var idsSeen = [String: String]()
    iterateStrings { str in
      let id = map!.deterministicUUIDString(value: str)
      idsSeen[str] = id
    }
    iterateStrings { str in
      let id = map!.deterministicUUIDString(value: str)
      let seenID = idsSeen[str]!
      XCTAssertEqual(id, seenID, "Hash for \(str) was not unique: \(id) vs \(seenID)")
    }
  }
  
  static var allTests = [
    ("testUniqueness", testUniqueness),
    ("testDeterminism", testDeterminism),
  ]
}

import Foundation
import XCTest

@testable import PromotedAIMetricsSDK

final class IDMapTests: XCTestCase {

  private var map: IDMap?
  
  private static let testBits = 16

  public override func setUp() {
    super.setUp()
    map = IDMap()
  }
  
  private func iterateStrings(block: (String) -> Void) {
    for i in 0 ..< (1 << IDMapTests.testBits) {
      let str = String(format: "%02x", i)
      block(str)
    }
  }
  
  func testUniqueness() {
    var idsSeen = [String: String]()
    iterateStrings { str in
      let id = map![str]
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
      let id = map![str]
      idsSeen[str] = id
    }
    iterateStrings { str in
      let id = map![str]
      let seenID = idsSeen[str]!
      XCTAssertEqual(id, seenID, "Hash for \(str) was not unique: \(id) vs \(seenID)")
    }
  }
  
  static var allTests = [
    ("testUniqueness", testUniqueness),
    ("testDeterminism", testDeterminism),
  ]
}

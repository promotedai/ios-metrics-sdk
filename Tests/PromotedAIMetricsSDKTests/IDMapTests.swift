import Foundation
import XCTest

@testable import PromotedAIMetricsSDK

final class IDMapTests: XCTestCase {

  private var map: IDMap?

  public override func setUp() {
    super.setUp()
    map = IDMap(namespace: "foobar")
  }
  
  private func iterateStrings(block: (String) -> Void) {
    let chars = "0123456789abcdef"
    for c0 in chars {
      for c1 in chars {
        for c2 in chars {
          for c3 in chars {
            for c4 in chars {
              let str = "\(c0)\(c1)\(c2)\(c3)\(c4)"
              block(str)
            }
          }
        }
      }
    }
  }
  
  func testPerformance() {
    let dictionaryBefore = Date().timeIntervalSince1970
    var dictionary = [String: String]()
    iterateStrings { str in
      dictionary[str] = UUID().uuidString
    }
    let dictionaryAfter = Date().timeIntervalSince1970
    let dictionaryElapsed = dictionaryAfter - dictionaryBefore
    print("Dictionary: \(dictionaryElapsed) sec")
    
    let idMapBefore = Date().timeIntervalSince1970
    let idMap = IDMap(namespace: "baz")
    iterateStrings { str in
      _ = idMap[str]
    }
    let idMapAfter = Date().timeIntervalSince1970
    let idMapElapsed = idMapAfter - idMapBefore
    print("IDMap: \(idMapElapsed) sec")
  }
  
  static var allTests = [
    ("testPerformance", testPerformance),
  ]
}

import Foundation
import XCTest

@testable import PromotedFirebaseRemoteConfig

final class StringCaseConversionTests: XCTestCase {

  func testSnakeCase() {
    XCTAssertEqual("json", "json".toSnakeCase())
    XCTAssertEqual("batch_summaries", "batchSummaries".toSnakeCase())
    XCTAssertEqual(
      "call_details_and_stack_traces",
      "callDetailsAndStackTraces".toSnakeCase()
    )
  }

  func testCamelCase() {
    XCTAssertEqual("json", "json".toCamelCase())
    XCTAssertEqual("batchSummaries", "batch_summaries".toCamelCase())
    XCTAssertEqual(
      "callDetailsAndStackTraces",
      "call_details_and_stack_traces".toCamelCase()
    )
  }
}

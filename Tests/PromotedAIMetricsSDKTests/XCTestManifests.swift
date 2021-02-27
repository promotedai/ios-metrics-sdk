import XCTest

#if !canImport(ObjectiveC)
public func allTests() -> [XCTestCaseEntry] {
  return [
    testCase(CollectionViewImpressionLoggerTests.allTests),
    testCase(MetricsLoggerTests.allTests),
  ]
}
#endif

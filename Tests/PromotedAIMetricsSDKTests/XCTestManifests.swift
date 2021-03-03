import XCTest

#if !canImport(ObjectiveC)
public func allTests() -> [XCTestCaseEntry] {
  return [
    testCase(CollectionViewImpressionLoggerTests.allTests),
    testCase(MetricsLoggerTests.allTests),
    testCase(NetworkConnectionTests.allTests),
    testCase(SHA1IDMapTests.allTests),
  ]
}
#endif

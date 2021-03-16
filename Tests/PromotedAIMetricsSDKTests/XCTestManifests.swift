import XCTest

#if !canImport(ObjectiveC)
public func allTests() -> [XCTestCaseEntry] {
  return [
    testCase(ImpressionLoggerTests.allTests),
    testCase(MetricsLoggerTests.allTests),
    testCase(NetworkConnectionTests.allTests),
    testCase(ScrollTrackerTests.allTests),
    testCase(SHA1IDMapTests.allTests),
  ]
}
#endif

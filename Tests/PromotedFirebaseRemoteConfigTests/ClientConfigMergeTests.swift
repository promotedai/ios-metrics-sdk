import Foundation
import XCTest

@testable import PromotedCore
@testable import PromotedCoreTestHelpers
@testable import PromotedFirebaseRemoteConfig

final class ClientConfigMergeTests: XCTestCase {

  private func assertLoggedMessagesEqualNoOrder(
    _ expected: [(PendingLogMessages.LogLevel, String)],
    _ actual: PendingLogMessages,
    file: StaticString = #filePath,
    line: UInt = #line
  ) {
    XCTAssertEqual(
      Set(expected.map {
        "\($0.0.rawValue): \($0.1)"
      }),
      Set(actual.messages.map {
        "\($0.level.rawValue): \($0.message)"
      }),
      file: file,
      line: line)
  }

  func testMerge() {
    let config = ClientConfig()
    config.disableAssertInValidationForTesting()

    let url = "https://fake2.promoted.ai/hippo/potamus"
    let dictionary = [
      "metrics_logging_url": url,
      "metrics_logging_api_key": "hello-world",
      "logging_flush_interval": "30.0",
      "flush_logging_on_resign_active": "false",
      "xray_level": "batchSummaries",
      "os_log_level": "debug",
    ]
    var messages = PendingLogMessages()
    config.merge(from: dictionary, messages: &messages)

    assertLoggedMessagesEqualNoOrder([
      (.info,
       "Read from remote config: metrics_logging_url = \(url)"),
      (.info,
       "Read from remote config: metrics_logging_api_key = hello-world"),
      (.info,
       "Read from remote config: logging_flush_interval = 30.0"),
      (.info,
       "Read from remote config: flush_logging_on_resign_active = false"),
      (.info, "Read from remote config: xray_level = 2"),
      (.info, "Read from remote config: os_log_level = 5"),
    ], messages)

    // Changed values.
    XCTAssertEqual(url, config.metricsLoggingURL)
    XCTAssertEqual("hello-world", config.metricsLoggingAPIKey)
    XCTAssertEqual(30.0, config.loggingFlushInterval, accuracy: 0.001)
    XCTAssertFalse(config.flushLoggingOnResignActive)
    XCTAssertEqual(.batchSummaries, config.xrayLevel)
    XCTAssertEqual(.debug, config.osLogLevel)

    // Unchanged values (should be default).
    XCTAssertTrue(config.loggingEnabled)
    XCTAssertEqual("", config.devMetricsLoggingURL)
    XCTAssertEqual("", config.devMetricsLoggingAPIKey)
    XCTAssertEqual(.binary, config.metricsLoggingWireFormat)
    XCTAssertEqual(
      0.5, config.scrollTrackerVisibilityThreshold, accuracy: 0.001
    )
    XCTAssertEqual(
      1.0, config.scrollTrackerDurationThreshold, accuracy: 0.001
    )
    XCTAssertEqual(
      0.5, config.scrollTrackerUpdateFrequency, accuracy: 0.001
    )
    XCTAssertFalse(config.diagnosticsIncludeBatchSummaries)
    XCTAssertFalse(config.diagnosticsIncludeAncestorIDHistory)
  }

  func testUnusedKey() {
    let config = ClientConfig()
    config.disableAssertInValidationForTesting()

    let url = "https://fake2.promoted.ai/hippo/potamus"
    let dictionary = [
      "metrics_logging_url": url,
      "foo_bar": "hello-world",
    ]
    var messages = PendingLogMessages()
    config.merge(from: dictionary, messages: &messages)

    assertLoggedMessagesEqualNoOrder([
      (.warning, "Unused key in remote config: foo_bar"),
      (.info, "Read from remote config: metrics_logging_url = \(url)"),
    ], messages)

    XCTAssertEqual(url, config.metricsLoggingURL)
  }

  func testBadValues() {
    let config = ClientConfig()
    config.disableAssertInValidationForTesting()

    let url = "https://fake2.promoted.ai/hippo/potamus"
    let dictionary = [
      "metrics_logging_url": url,
      "logging_flush_interval": "hello-world",
      "logging_enabled": "super-mario-world",
      "xray_level": "oh-what-a-wonderful-world",
    ]
    var messages = PendingLogMessages()
    config.merge(from: dictionary, messages: &messages)

    assertLoggedMessagesEqualNoOrder([
      (.warning, "No viable conversion for remote config value: " +
        "logging_flush_interval = hello-world"),
      (.warning, "No viable conversion for remote config value: " +
        "logging_enabled = super-mario-world"),
      (.warning, "No viable conversion for remote config value: " +
        "xray_level = oh-what-a-wonderful-world"),
      (.info, "Read from remote config: metrics_logging_url = \(url)"),
    ], messages)

    XCTAssertEqual(url, config.metricsLoggingURL)
    XCTAssertEqual(10.0, config.loggingFlushInterval, accuracy: 0.001)
    XCTAssertTrue(config.loggingEnabled)
    XCTAssertEqual(.none, config.xrayLevel)
  }
}

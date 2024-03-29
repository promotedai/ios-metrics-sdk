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
      line: line
    )
  }

  func testMerge() {
    var config = ClientConfig()
    config.disableAssertInValidationForTesting()

    let url = "https://fake2.promoted.ai/hippo/potamus"
    let dictionary = [
      "ai_promoted_metrics_logging_url": url,
      "ai_promoted_metrics_logging_api_key": "hello-world",
      "ai_promoted_metrics_logging_request_headers": """
      {
        "foo": "bar",
        "batman": "robin"
      }
      """,
      "ai_promoted_logging_flush_interval": "30.0",
      "ai_promoted_flush_logging_on_resign_active": "false",
      "ai_promoted_xray_level": "batchSummaries",
      "ai_promoted_os_log_level": "debug",
    ]
    var messages = PendingLogMessages()
    config.merge(from: dictionary, messages: &messages)

    assertLoggedMessagesEqualNoOrder([
      (.info, "Read from remote config: " +
        "ai_promoted_metrics_logging_url = <<sha256: e39ead058a0475ec…>>"),
      (.info, "Read from remote config: " +
        "ai_promoted_metrics_logging_api_key = <<sha256: afa27b44d43b02a9…>>"),
      (.info, "Read from remote config: " +
        "ai_promoted_logging_flush_interval = 30.0"),
      (.info, "Read from remote config: " +
        "ai_promoted_flush_logging_on_resign_active = false"),
      (.info, "Read from remote config: " +
        "ai_promoted_xray_level = batchSummaries"),
      (.info, "Read from remote config: " +
        "ai_promoted_os_log_level = debug"),
      (.info, "Read from remote config: " +
        "ai_promoted_metrics_logging_request_headers = {\n" +
        "    batman = robin;\n" +
        "    foo = bar;\n}"
      ),
    ], messages)

    // Changed values.
    XCTAssertEqual(url, config.metricsLoggingURL)
    XCTAssertEqual("hello-world", config.metricsLoggingAPIKey)
    XCTAssertEqual(
      ["foo": "bar", "batman": "robin"],
      config.metricsLoggingRequestHeaders
    )
    XCTAssertEqual(30.0, config.loggingFlushInterval, accuracy: 0.001)
    XCTAssertFalse(config.flushLoggingOnResignActive)
    XCTAssertEqual(.batchSummaries, config.xrayLevel)
    XCTAssertEqual(.debug, config.osLogLevel)

    // Unchanged values (should be default).
    XCTAssertTrue(config.loggingEnabled)
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
    var config = ClientConfig()
    config.disableAssertInValidationForTesting()

    let url = "https://fake2.promoted.ai/hippo/potamus"
    let dictionary = [
      "ai_promoted_metrics_logging_url": url,
      "ai_promoted_foo_bar": "hello-world",
    ]
    var messages = PendingLogMessages()
    config.merge(from: dictionary, messages: &messages)

    assertLoggedMessagesEqualNoOrder([
      (.warning, "Unrecognized key in remote config: ai_promoted_foo_bar " +
        "(ignoring)"),
      (.info, "Read from remote config: " +
        "ai_promoted_metrics_logging_url = <<sha256: e39ead058a0475ec…>>"),
    ], messages)

    XCTAssertEqual(url, config.metricsLoggingURL)
  }

  func testBadValues() {
    var config = ClientConfig()
    config.disableAssertInValidationForTesting()

    let url = "https://fake2.promoted.ai/hippo/potamus"
    let dictionary = [
      "ai_promoted_metrics_logging_url": url,
      "ai_promoted_metrics_logging_request_headers": "not a json object!!",
      "ai_promoted_logging_flush_interval": "hello-world",
      "ai_promoted_logging_enabled": "super-mario-world",
      "ai_promoted_xray_level": "oh-what-a-wonderful-world",
    ]
    var messages = PendingLogMessages()
    config.merge(from: dictionary, messages: &messages)

    assertLoggedMessagesEqualNoOrder([
      (.warning, "No viable conversion for remote config value: " +
        "ai_promoted_metrics_logging_request_headers = not a json object!! (ignoring)"),
      (.warning, "No viable conversion for remote config value: " +
        "ai_promoted_logging_flush_interval = hello-world (ignoring)"),
      (.warning, "No viable conversion for remote config value: " +
        "ai_promoted_logging_enabled = super-mario-world (ignoring)"),
      (.warning, "No viable conversion for remote config value: " +
        "ai_promoted_xray_level = oh-what-a-wonderful-world (ignoring)"),
      (.info, "Read from remote config: " +
        "ai_promoted_metrics_logging_url = <<sha256: e39ead058a0475ec…>>"),
    ], messages)

    XCTAssertEqual(url, config.metricsLoggingURL)
    XCTAssertEqual(10.0, config.loggingFlushInterval, accuracy: 0.001)
    XCTAssertTrue(config.loggingEnabled)
    XCTAssertEqual(.none, config.xrayLevel)
  }

  func testOutOfBoundsValues() {
    var config = ClientConfig()
    config.disableAssertInValidationForTesting()

    let dictionary = [
      "ai_promoted_logging_flush_interval": "0.0",
    ]
    var messages = PendingLogMessages()
    config.merge(from: dictionary, messages: &messages)

    assertLoggedMessagesEqualNoOrder([
      (.warning, "Attempted to set invalid value: " +
        "ai_promoted_logging_flush_interval = 0.0 (using 1 instead)"),
      (.info, "Read from remote config: " +
        "ai_promoted_logging_flush_interval = 0.0"),
    ], messages)

    XCTAssertEqual(1.0, config.loggingFlushInterval, accuracy: 0.001)
  }
}

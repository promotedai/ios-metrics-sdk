import Foundation
import XCTest

@testable import PromotedCore
@testable import PromotedCoreTestHelpers

final class ClientConfigServiceTests: ModuleTestCase {

  func testLocalCache() {
    let url = "https://fake.promoted.ai"
    var config = ClientConfig()
    config.metricsLoggingURL = url
    config.metricsLoggingAPIKey = "apikey!"
    config.xrayLevel = .callDetails

    let configData = try! JSONEncoder().encode(config)
    store.clientConfig = configData
    module.clientConfigService.fetchClientConfig { _ in }

    // Don't use module.clientConfig here because TestModule
    // bypasses ClientConfigService.
    let fetchedConfig = module.clientConfigService.config

    XCTAssertEqual(url, fetchedConfig.metricsLoggingURL)
    XCTAssertEqual("apikey!", fetchedConfig.metricsLoggingAPIKey)
    XCTAssertEqual(.callDetails, fetchedConfig.xrayLevel)
  }

  func testCachesRemoteValue() {
    let url = "https://fake2.promoted.ai"
    var remoteConfig = ClientConfig()
    remoteConfig.metricsLoggingURL = url
    remoteConfig.metricsLoggingAPIKey = "apikey!!"
    remoteConfig.xrayLevel = .callDetails
    remoteConfigConnection.config = remoteConfig

    module.clientConfigService.fetchClientConfig { result in
      XCTAssertNotNil(result.config)
      XCTAssertNil(result.error)
      guard let configData = self.store.clientConfig else {
        XCTFail("ClientConfig not written to PersistentStore")
        return
      }
      do {
        let deserializedConfig = try JSONDecoder().decode(
          ClientConfig.self, from: configData
        )
        XCTAssertEqual(url, deserializedConfig.metricsLoggingURL)
        XCTAssertEqual("apikey!!", deserializedConfig.metricsLoggingAPIKey)
        XCTAssertEqual(.callDetails, deserializedConfig.xrayLevel)
      } catch {
        XCTFail(String(describing: error))
      }
    }
  }

  func testDiagnosticsSamplingEndDateExpired() {
    let url = "https://fake.promoted.ai"
    module.initialConfig.metricsLoggingURL = url
    module.initialConfig.metricsLoggingAPIKey = "apikey!"
    module.initialConfig.diagnosticsSamplingPercentage = 100
    module.initialConfig.diagnosticsSamplingEndDateString = "1980-01-01"
    module.remoteConfigConnection = nil
    clock.now = Date(ymdString: "2021-12-01")!.timeIntervalSince1970

    let logUserID = "FFF19C59-E1D0-40D1-A162-5BA9918302A4"
    let uuid = UUID(uuidString: logUserID)!
    XCTAssertEqual(99, uuid.stableHashValueMod(100))
    store.logUserID = logUserID

    var callbackCalled = false
    let service = ClientConfigService(deps: module)
    service.fetchClientConfig { result in
      let config = result.config!
      XCTAssertFalse(config.diagnosticsIncludeBatchSummaries)
      XCTAssertFalse(config.diagnosticsIncludeAncestorIDHistory)
      XCTAssertFalse(config.eventsIncludeIDProvenances)
      XCTAssertFalse(config.eventsIncludeClientPositions)
      let message = result.messages.messages.last!
      XCTAssertEqual(
        "Config specifies diagnosticsSamplingPercentage=100% " +
        "and end date (1980-01-01) earlier than or equal to " +
        "current date (2021-12-01). Skipping.",
        message.message
      )
      callbackCalled = true
    }
    XCTAssertTrue(callbackCalled)
  }

  func testDiagnosticsSamplingNotInSample() {
    let url = "https://fake.promoted.ai"
    module.initialConfig.metricsLoggingURL = url
    module.initialConfig.metricsLoggingAPIKey = "apikey!"
    module.initialConfig.diagnosticsSamplingPercentage = 1
    module.initialConfig.diagnosticsSamplingEndDateString = "2022-01-01"
    module.remoteConfigConnection = nil
    clock.now = Date(ymdString: "2021-12-01")!.timeIntervalSince1970

    let logUserID = "FFF19C59-E1D0-40D1-A162-5BA9918302A4"
    let uuid = UUID(uuidString: logUserID)!
    XCTAssertEqual(99, uuid.stableHashValueMod(100))
    store.logUserID = logUserID

    var callbackCalled = false
    let service = ClientConfigService(deps: module)
    service.fetchClientConfig { result in
      let config = result.config!
      XCTAssertFalse(config.diagnosticsIncludeBatchSummaries)
      XCTAssertFalse(config.diagnosticsIncludeAncestorIDHistory)
      XCTAssertFalse(config.eventsIncludeIDProvenances)
      XCTAssertFalse(config.eventsIncludeClientPositions)
      let message = result.messages.messages.last!
      XCTAssertEqual(
        "Config specifies diagnosticsSamplingPercentage=1% " +
        "and end date (2022-01-01) but random sample skipped.",
        message.message
      )
      callbackCalled = true
    }
    XCTAssertTrue(callbackCalled)
  }

  func testDiagnosticsSamplingInSample() {
    let url = "https://fake.promoted.ai"
    module.initialConfig.metricsLoggingURL = url
    module.initialConfig.metricsLoggingAPIKey = "apikey!"
    module.initialConfig.diagnosticsSamplingPercentage = 1
    module.initialConfig.diagnosticsSamplingEndDateString = "2022-01-01"
    module.remoteConfigConnection = nil
    clock.now = Date(ymdString: "2021-12-01")!.timeIntervalSince1970

    let logUserID = "78490C6B-CB52-4384-87FE-52313D1D45DC"
    let uuid = UUID(uuidString: logUserID)!
    XCTAssertEqual(0, uuid.stableHashValueMod(100))
    store.logUserID = logUserID

    var callbackCalled = false
    let service = ClientConfigService(deps: module)
    service.fetchClientConfig { result in
      let config = result.config!
      XCTAssertTrue(config.diagnosticsIncludeBatchSummaries)
      XCTAssertTrue(config.diagnosticsIncludeAncestorIDHistory)
      XCTAssertTrue(config.eventsIncludeIDProvenances)
      XCTAssertTrue(config.eventsIncludeClientPositions)
      let message = result.messages.messages.last!
      XCTAssertEqual(
        "Config specifies diagnosticsSamplingPercentage=1% " +
        "and end date (2022-01-01). Enabling all diagnostics.",
        message.message
      )
      callbackCalled = true
    }
    XCTAssertTrue(callbackCalled)
  }
}

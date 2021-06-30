import Foundation
import XCTest

@testable import PromotedCore
@testable import PromotedCoreTestHelpers

final class ClientConfigServiceTests: ModuleTestCase {

  func testLocalCache() {
    initialConfig.metricsLoggingURL = "https://fake.promoted.ai"
    initialConfig.metricsLoggingAPIKey = "apikey!"
    let serializedConfig: PersistentStore.ConfigDict = [
      "metricsLoggingURL": "https://fake2.promoted.ai",
      "xrayLevel": ClientConfig.XrayLevel.callDetails.rawValue
    ]
    store.clientConfig = serializedConfig
    try! module.clientConfigService.fetchClientConfig()

    // Don't use module.clientConfig here because TestModule
    // bypasses ClientConfigService.
    let config = module.clientConfigService.config

    // Overwritten.
    XCTAssertEqual("https://fake2.promoted.ai", config.metricsLoggingURL)
    XCTAssertEqual(.callDetails, config.xrayLevel)

    // Not overwritten.
    XCTAssertEqual("apikey!", config.metricsLoggingAPIKey)
  }

  func testCachesRemoteValue() {
    let url = "https://fake3.promoted.ai"
    remoteConfigConnection.config.metricsLoggingURL = url
    remoteConfigConnection.config.xrayLevel = .callDetails

    try! module.clientConfigService.fetchClientConfig { config, error in
      guard let config = config else {
        XCTFail("Callback did not provide ClientConfig")
        return
      }
      XCTAssertEqual(url, config.metricsLoggingURL)
      XCTAssertEqual(.callDetails, config.xrayLevel)
      XCTAssertNil(error)
      guard let configDict = self.store.clientConfig else {
        XCTFail("ClientConfig not written to PersistentStore")
        return
      }
      XCTAssertEqual(url, configDict["metricsLoggingURL"])
      XCTAssertEqual(
        ClientConfig.XrayLevel.callDetails.rawValue,
        configDict["xrayLevel"]?.base as? Int
      )
    }
  }
}

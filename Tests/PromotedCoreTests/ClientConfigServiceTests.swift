import Foundation
import XCTest

@testable import PromotedCore
@testable import PromotedCoreTestHelpers

final class ClientConfigServiceTests: ModuleTestCase {

  func testLocalCache() throws {
    let config = ClientConfig()
    let url = "https://fake.promoted.ai"
    config.metricsLoggingURL = url
    config.metricsLoggingAPIKey = "apikey!"
    config.xrayLevel = .callDetails

    let configData = try JSONEncoder().encode(config)
    store.clientConfig = configData
    try! module.clientConfigService.fetchClientConfig()

    // Don't use module.clientConfig here because TestModule
    // bypasses ClientConfigService.
    let fetchedConfig = module.clientConfigService.config

    XCTAssertEqual(url, fetchedConfig.metricsLoggingURL)
    XCTAssertEqual("apikey!", fetchedConfig.metricsLoggingAPIKey)
    XCTAssertEqual(.callDetails, fetchedConfig.xrayLevel)
  }

  func testCachesRemoteValue() {
    let url = "https://fake2.promoted.ai"
    remoteConfigConnection.config.metricsLoggingURL = url
    remoteConfigConnection.config.metricsLoggingAPIKey = "apikey!!"
    remoteConfigConnection.config.xrayLevel = .callDetails

    try! module.clientConfigService.fetchClientConfig { config, error in
      XCTAssertNotNil(config)
      XCTAssertNil(error)
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
}

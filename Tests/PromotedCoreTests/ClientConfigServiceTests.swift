import Foundation
import XCTest

@testable import PromotedCore
@testable import PromotedCoreTestHelpers

final class ClientConfigServiceTests: ModuleTestCase {

  func testLocalCache() {
    let url = "https://fake.promoted.ai"
    module.clientConfig.metricsLoggingURL = url
    module.clientConfig.metricsLoggingAPIKey = "apikey!"
    module.clientConfig.xrayLevel = .callDetails

    let configData = try! JSONEncoder().encode(module.clientConfig)
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
}

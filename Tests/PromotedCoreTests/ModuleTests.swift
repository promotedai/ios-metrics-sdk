import Foundation
import XCTest

@testable import PromotedCore
@testable import PromotedCoreTestHelpers

/** Cyclical dependencies will break this test. */
final class ModuleTests: XCTestCase {
  var analyticsConnection: AnalyticsConnection!
  var networkConnection: NetworkConnection!
  var initialConfig: ClientConfig!

  override func setUp() {
    super.setUp()
    analyticsConnection = FakeAnalyticsConnection()
    networkConnection = FakeNetworkConnection()
    initialConfig = ClientConfig()
    initialConfig.metricsLoggingURL = "https://fake.promoted.ai/metrics"
    initialConfig.metricsLoggingAPIKey = "apikey!"
  }

  func testBaseModule() throws {
    let module = Module(initialConfig: initialConfig,
                        networkConnection: networkConnection)
    try module.validateModuleConfigDependencies()
    try module.startLoggingServices()
    XCTAssertNil(module.analytics)
    XCTAssertNil(module.osLogSource)
    XCTAssertNil(module.xray)
  }

  func testModuleWithXray() throws {
    initialConfig.xrayLevel = .batchSummaries
    let module = Module(initialConfig: initialConfig,
                        networkConnection: networkConnection)
    try module.validateModuleConfigDependencies()
    try module.startLoggingServices()
    XCTAssertNil(module.analytics)
    XCTAssertNil(module.osLogSource)
    XCTAssertNotNil(module.xray)
  }

  func testModuleWithOSLog() throws {
    initialConfig.osLogLevel = .info
    let module = Module(initialConfig: initialConfig,
                        networkConnection: networkConnection)
    try module.validateModuleConfigDependencies()
    try module.startLoggingServices()
    XCTAssertNil(module.analytics)
    XCTAssertNotNil(module.osLogSource)
    XCTAssertNil(module.xray)
  }

  func testModuleWithAnalytics() throws {
    let module = Module(initialConfig: initialConfig,
                        analyticsConnection: analyticsConnection,
                        networkConnection: networkConnection)
    try module.validateModuleConfigDependencies()
    try module.startLoggingServices()
    XCTAssertNotNil(module.analytics)
    XCTAssertNil(module.osLogSource)
    XCTAssertNil(module.xray)
  }

  func testNoNetworkConnection() {
    let module = Module(initialConfig: initialConfig)
    XCTAssertThrowsError(try module.validateModuleConfigDependencies())
  }
}

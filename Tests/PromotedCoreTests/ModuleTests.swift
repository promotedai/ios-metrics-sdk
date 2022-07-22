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
    initialConfig.metricsLoggingErrorHandling = .none
    initialConfig.metricsLoggingURL = "https://fake.promoted.ai/metrics"
    initialConfig.metricsLoggingAPIKey = "apikey!"
    initialConfig.osLogLevel = .none
  }

  private func testAllFields(module: Module) {
    let mirror = Mirror(reflecting: module)
    for child in mirror.children {
      _ = child.value
    }
    _ = module.clientConfig
  }

  func testBaseModule() throws {
    let module = Module(
      initialConfig: initialConfig,
      networkConnection: networkConnection
    )
    try module.validateModuleConfigDependencies()
    try module.startLoggingServices()
    XCTAssertNil(module.analytics)
    XCTAssertNil(module.errorHandler)
    XCTAssertNil(module.osLog(category: "ModuleTests"))
    XCTAssertNil(module.xray)
    testAllFields(module: module)
  }

  func testModuleWithXray() throws {
    initialConfig.xrayLevel = .batchSummaries
    let module = Module(
      initialConfig: initialConfig,
      networkConnection: networkConnection
    )
    try module.validateModuleConfigDependencies()
    try module.startLoggingServices()
    XCTAssertNil(module.analytics)
    XCTAssertNil(module.errorHandler)
    XCTAssertNil(module.osLog(category: "ModuleTests"))
    XCTAssertNotNil(module.xray)
    testAllFields(module: module)
  }

  func testModuleWithOSLog() throws {
    initialConfig.osLogLevel = .info
    let module = Module(
      initialConfig: initialConfig,
      networkConnection: networkConnection
    )
    try module.validateModuleConfigDependencies()
    try module.startLoggingServices()
    XCTAssertNil(module.analytics)
    XCTAssertNotNil(module.errorHandler)  // Logging enables ErrorHandler
    XCTAssertNotNil(module.osLog(category: "ModuleTests"))
    XCTAssertNil(module.xray)
    testAllFields(module: module)
  }

  func testModuleWithAnalytics() throws {
    let module = Module(
      initialConfig: initialConfig,
      analyticsConnection: analyticsConnection,
      networkConnection: networkConnection
    )
    try module.validateModuleConfigDependencies()
    try module.startLoggingServices()
    XCTAssertNotNil(module.analytics)
    XCTAssertNil(module.errorHandler)
    XCTAssertNil(module.osLog(category: "ModuleTests"))
    XCTAssertNil(module.xray)
    testAllFields(module: module)
  }

  func testModuleWithErrorHandler() throws {
    initialConfig.metricsLoggingErrorHandling = .modalDialog
    let module = Module(
      initialConfig: initialConfig,
      networkConnection: networkConnection
    )
    try module.validateModuleConfigDependencies()
    try module.startLoggingServices()
    XCTAssertNil(module.analytics)
    XCTAssertNotNil(module.errorHandler)
    XCTAssertNil(module.osLog(category: "ModuleTests"))
    XCTAssertNil(module.xray)
    testAllFields(module: module)
  }

  func testNoNetworkConnection() {
    let module = Module(initialConfig: initialConfig)
    XCTAssertThrowsError(try module.validateModuleConfigDependencies())
  }
}

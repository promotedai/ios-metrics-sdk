import Foundation
import XCTest

@testable import PromotedCore

/**
 Base class that provides a `TestModule` with convenience properties.
 Module and all associated properties are recreated for each test in `setUp()`.
 */
open class ModuleTestCase: XCTestCase {
  var module: TestModule!
  var analyticsConnection: FakeAnalyticsConnection { module.fakeAnalyticsConnection }
  var config: ClientConfig { module.clientConfig }
  var connection: FakeNetworkConnection { module.fakeNetworkConnection }
  var clock: FakeClock { module.fakeClock }
  var idMap: FakeIDMap { module.fakeIDMap }
  var initialConfig: ClientConfig { module.initialConfig }
  var remoteConfigConnection: FakeRemoteConfigConnection { module.fakeRemoteConfigConnection }
  var store: FakePersistentStore { module.fakePersistentStore }
  var uiState: FakeUIState { module.fakeUIState }

  open override func setUp() {
    super.setUp()
    module = TestModule()
  }
}

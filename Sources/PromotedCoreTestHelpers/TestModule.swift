import Foundation
import os.log

@testable import PromotedCore

/** Module for use with testing with convenient fakes. */
final class TestModule: AllDeps {
  // MARK: - Fakes
  var fakeAnalyticsConnection = FakeAnalyticsConnection()

  var fakeBuildInfo = FakeBuildInfo()

  var fakeClock = FakeClock()

  var fakeDeviceInfo = FakeDeviceInfo()

  var fakeIDMap = FakeIDMap()

  var fakeNetworkConnection = FakeNetworkConnection()

  var fakePersistentStore = FakePersistentStore()

  var fakeRemoteConfigConnection = FakeRemoteConfigConnection()

  var fakeUIState = FakeUIState()

  // MARK: - AllDeps
  var analytics: Analytics? = nil

  lazy var analyticsConnection: AnalyticsConnection? =
    fakeAnalyticsConnection

  lazy var errorHandler: ErrorHandler? = ErrorHandler(deps: self)

  lazy var buildInfo: BuildInfo = fakeBuildInfo

  lazy var clientConfigService: ClientConfigService = ClientConfigService(deps: self)

  var clientConfig = ClientConfig()

  var initialConfig = ClientConfig()

  lazy var clock: Clock = fakeClock

  lazy var deviceInfo: DeviceInfo = fakeDeviceInfo

  lazy var idMap: IDMap = fakeIDMap

  lazy var networkConnection: NetworkConnection =
    fakeNetworkConnection

  var operationMonitor = OperationMonitor()

  func osLog(category: String) -> OSLog? {
    osLogSource?.osLog(category: category)
  }

  var osLogSource: OSLogSource? = nil

  lazy var persistentStore: PersistentStore = fakePersistentStore

  lazy var remoteConfigConnection: RemoteConfigConnection? =
    fakeRemoteConfigConnection

  lazy var uiState: UIState = fakeUIState

  func viewTracker() -> ViewTracker { ViewTracker(deps: self) }

  var xray: Xray? = nil
}

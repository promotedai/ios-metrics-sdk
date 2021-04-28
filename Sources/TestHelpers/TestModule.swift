import Foundation
import os.log

@testable import PromotedAIMetricsSDK

class TestModule: AllDeps {
  // MARK: - Fakes
  var fakeClock = FakeClock()

  var fakeDeviceInfo = FakeDeviceInfo()

  var fakeIDMap = FakeIDMap()

  var fakeNetworkConnection = FakeNetworkConnection()

  var fakePersistentStore = FakePersistentStore()

  var fakeUIState = FakeUIState()

  // MARK: - AllDeps
  var clientConfigService: ClientConfigService {
    LocalClientConfigService(initialConfig: initialConfig)
  }

  var clientConfig = ClientConfig()

  var initialConfig = ClientConfig()

  lazy var clock: Clock = fakeClock

  lazy var deviceInfo: DeviceInfo = fakeDeviceInfo

  lazy var idMap: IDMap = fakeIDMap

  lazy var networkConnection: NetworkConnection = fakeNetworkConnection

  var operationMonitor = OperationMonitor()

  func osLog(category: String) -> OSLog? { osLogSource?.osLog(category: category) }

  var osLogSource: OSLogSource? = nil

  lazy var persistentStore: PersistentStore = fakePersistentStore

  lazy var uiState: UIState = fakeUIState

  lazy var viewTracker: ViewTracker = ViewTracker(deps: self)

  var xray: Xray? = nil
}

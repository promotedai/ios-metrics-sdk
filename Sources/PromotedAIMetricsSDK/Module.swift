import Foundation
import os.log

@objc(PROModuleConfig)
public class ModuleConfig: NSObject {
  @objc public var initialConfig = ClientConfig()
  public var clientConfigService: ClientConfigService? = nil
  public var networkConnection: NetworkConnection? = nil
  public var persistentStore: PersistentStore? = nil
}

typealias AllDeps = ClientConfigSource & ClientConfigServiceSource & ClockSource &
                    DeviceInfoSource & IDMapSource & NetworkConnectionSource &
                    OperationMonitorSource & OSLogSource & PersistentStoreSource &
                    UIStateSource & ViewTrackerSource & XraySource

class Module: AllDeps {
  var clientConfig: ClientConfig {
    clientConfigService.config
  }

  lazy var clientConfigService: ClientConfigService = {
    clientConfigServiceSpec ?? LocalClientConfigService(initialConfig: initialConfig)
  } ()
  private let clientConfigServiceSpec: ClientConfigService?

  let clock: Clock = SystemClock()
  
  let deviceInfo: DeviceInfo = IOSDeviceInfo()
  
  let idMap: IDMap = SHA1IDMap()
  
  let initialConfig: ClientConfig

  lazy var networkConnection: NetworkConnection = {
    networkConnectionSpec ?? GTMSessionFetcherConnection()
  } ()
  private let networkConnectionSpec: NetworkConnection?

  let operationMonitor = OperationMonitor()

  func osLog(category: String) -> OSLog? {
    osLogSource?.osLog(category: category)
  }

  lazy var osLogSource: OSLogSource? = {
    clientConfig.osLogEnabled ? SystemOSLogSource() : nil
  } ()

  lazy var persistentStore: PersistentStore = {
    persistentStoreSpec ?? UserDefaultsPersistentStore()
  } ()
  private let persistentStoreSpec: PersistentStore?

  let uiState: UIState = UIKitState()

  lazy var viewTracker: ViewTracker = { ViewTracker(deps: self) } ()

  lazy var xray: Xray? = {
    clientConfig.xrayEnabled ? Xray(deps: self) : nil
  } ()

  convenience init(moduleConfig: ModuleConfig) {
    self.init(initialConfig: moduleConfig.initialConfig,
              clientConfigService: moduleConfig.clientConfigService,
              networkConnection: moduleConfig.networkConnection,
              persistentStore: moduleConfig.persistentStore)
  }

  init(initialConfig: ClientConfig,
       clientConfigService: ClientConfigService? = nil,
       networkConnection: NetworkConnection? = nil,
       persistentStore: PersistentStore? = nil) {
    self.initialConfig = initialConfig
    self.clientConfigServiceSpec = clientConfigService
    self.networkConnectionSpec = networkConnection
    self.persistentStoreSpec = persistentStore
  }
}

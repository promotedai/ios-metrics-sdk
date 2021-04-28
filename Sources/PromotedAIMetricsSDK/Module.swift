import Foundation
import os.log

/**
 Client-facing configuration for Promoted metrics logging library.
 Use this to provide custom or specific implementations of several
 library components.
 */
@objc(PROModuleConfig)
public class ModuleConfig: NSObject {
  @objc public var initialConfig = ClientConfig()
  // TODO: What if some specialization has dependencies?
  public var clientConfigService: ClientConfigService? = nil
  public var networkConnection: NetworkConnection? = nil
  public var persistentStore: PersistentStore? = nil
}

typealias ClientConfigDeps = ClientConfigSource & ClientConfigServiceSource

typealias InternalDeps = ClientConfigDeps &
                         ClockSource &
                         DeviceInfoSource &
                         IDMapSource &
                         OperationMonitorSource &
                         OSLogSource &
                         UIStateSource &
                         ViewTrackerSource &
                         XraySource

typealias NetworkConnectionDeps = InternalDeps & NetworkConnectionSource

typealias PersistentStoreDeps = InternalDeps & PersistentStoreSource

typealias AllDeps = InternalDeps &
                    ClientConfigDeps &
                    NetworkConnectionDeps &
                    PersistentStoreDeps

/**
 Owner of all dependencies in the logging library.

 # Protocol composition

 Promoted dependency management uses protocol composition to restrict
 allowed dependencies for each class while providing a central object
 to source those dependencies. The pattern is that each class that is
 a potential dependency has a corresponding `Source` protocol, and that
 protocol has a single property that returns an instance of the
 dependency. The property name should be the class name of the provided
 object in camelCase. For example, for `Clock`, the protocol is:
 ~~~
 protocol ClockSource {
   var clock: Clock { get }
 }
 ~~~
 Next, every class that has dependencies should specify those dependencies
 using these `Source` protocols. For example:
 ~~~
 class MyClass {
   typealias Deps = ClockSource & OperationMonitorSource
 
   private let clock: Clock
   private let monitor: OperationMonitor
 
   init(deps: Deps) {
     self.clock = deps.clock
     self.monitor = deps.operationMonitor
   }
 }
 ~~~
 When using this pattern to retrieve dependencies, as in the above:
 
 1. The owning class may use either owned or unowned references to any
    dependencies exposed as **properties** from its `Source` objects.
    No circular dependencies means that no retain cycles should exist.
 2. The owning class must own any dependencies exposed as **methods**
    in its `Source` objects. These dependencies are not owned by the
    `Source` objects or `Module`.
 3. The owning class should avoid holding a reference to the entire
    `deps` object and instead save its dependencies into properties.
 4. A class that has dependencies can also be a dependency in itself.
    In the example above, it is valid to have a `MyClassSource` and
    expose that in `Module`.
 
 # Adding new dependencies to `Module`
 
 ## Simple dependencies
 
 If you're adding an object with no public config and no other dependencies,
 create a new `let` property and expose it using its protocol type.
 ~~~
 let foo: Foo = MyFooClass()
 ~~~
 
 ## Dependencies with other dependencies
 
 If you're adding an object with dependencies, declare it as a
 `private(set) lazy var`. Then you can reference `self`.
 ~~~
 private(set) lazy var viewTracker: ViewTracker = ViewTracker(deps: self)
 ~~~
 
 ## Dependencies with public config
 
 If you're exposing a class for use in `ModuleConfig`, declare a second
 private property to hold the specialization from the module. Then
 declare the dependency property as a `private(set) lazy var` that checks
 the specialization, and then provides a default implementation.
 ~~~
 public class ModuleConfig: NSObject {
   public var networkConnection: NetworkConnection? = nil
 }

 class Module: AllDeps {
   private(set) lazy var networkConnection: NetworkConnection = {
     networkConnectionSpec ?? GTMSessionFetcherConnection()
   } ()
   private let networkConnectionSpec: NetworkConnection?
   init(...,
        networkConnection: NetworkConnection? = nil,
        ...) {
     self.networkConnectionSpec = networkConnection
   }
 }
 ~~~
 
 ## Computed dependencies
 
 Use a normal computed property for these.
 ~~~
 var clientConfig: ClientConfig {
   clientConfigService.config
 }
 ~~~

 # Testing
 
 If you need to use these dependencies in a unit test, see `TestModule`
 and `ModuleTestCase`.
 */
class Module: AllDeps {
  var clientConfig: ClientConfig {
    clientConfigService.config
  }

  private(set) lazy var clientConfigService: ClientConfigService = {
    clientConfigServiceSpec ?? LocalClientConfigService(initialConfig: initialConfig)
  } ()
  private let clientConfigServiceSpec: ClientConfigService?

  let clock: Clock = SystemClock()
  
  let deviceInfo: DeviceInfo = IOSDeviceInfo()
  
  let idMap: IDMap = SHA1IDMap()
  
  let initialConfig: ClientConfig

  private(set) lazy var networkConnection: NetworkConnection = {
    networkConnectionSpec ?? GTMSessionFetcherConnection()
  } ()
  private let networkConnectionSpec: NetworkConnection?

  let operationMonitor = OperationMonitor()

  func osLog(category: String) -> OSLog? {
    osLogSource?.osLog(category: category)
  }

  private(set) lazy var osLogSource: OSLogSource? = {
    clientConfig.osLogEnabled ? SystemOSLogSource() : nil
  } ()

  private(set) lazy var persistentStore: PersistentStore = {
    persistentStoreSpec ?? UserDefaultsPersistentStore()
  } ()
  private let persistentStoreSpec: PersistentStore?

  let uiState: UIState = UIKitState()

  private(set) lazy var viewTracker: ViewTracker = ViewTracker(deps: self)

  private(set) lazy var xray: Xray? = {
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

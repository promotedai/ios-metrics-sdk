import Foundation
import os.log

/**
 Client-facing configuration for Promoted metrics logging library.
 Use this to provide custom or specific implementations of several
 library components.
 
 Custom implementations of the classes exposed in `ModuleConfig` can't
 use internal dependencies. If you need any internal deps, pass them in
 as arguments instead of constructing the object with them. (If this
 becomes problematic, we will revisit.)
 */
@objc(PROModuleConfig)
public final class ModuleConfig: NSObject {
  @objc public var initialConfig = ClientConfig()
  public var analyticsConnection: AnalyticsConnection? = nil
  public var clientConfigService: ClientConfigService? = nil
  public var networkConnection: NetworkConnection? = nil
  public var persistentStore: PersistentStore? = nil

  private override init() {}

  /// Returns a new, unpopulated `ModuleConfig`.
  /// This does not provide a `NetworkConnection`. If you are not
  /// supplying your own `NetworkConnection`, you should use
  /// `defaultConfig()` from the `PromotedMetrics` dependency.
  @objc public static func coreConfig() -> ModuleConfig { ModuleConfig() }
}

typealias ClientConfigDeps = ClientConfigSource & ClientConfigServiceSource

typealias InternalDeps = AnalyticsSource &
                         ClientConfigDeps &
                         ClockSource &
                         DeviceInfoSource &
                         IDMapSource &
                         OperationMonitorSource &
                         OSLogSource &
                         UIStateSource &
                         ViewTrackerSource &
                         XraySource

typealias AnalyticsConnectionDeps = InternalDeps & AnalyticsConnectionSource

typealias NetworkConnectionDeps = InternalDeps & NetworkConnectionSource

typealias PersistentStoreDeps = InternalDeps & PersistentStoreSource

typealias AllDeps = InternalDeps &
                    AnalyticsConnectionDeps &
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
 ```swift
 protocol ClockSource {
   var clock: Clock { get }
 }
 ```
 Next, every class that has dependencies should specify those dependencies
 using these `Source` protocols. For example:
 ```swift
 class MyClass {
   typealias Deps = ClockSource & OperationMonitorSource
 
   private let clock: Clock
   private let monitor: OperationMonitor
 
   init(deps: Deps) {
     self.clock = deps.clock
     self.monitor = deps.operationMonitor
   }
 }
 ```
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
 ```swift
 let foo: Foo = MyFooClass()
 ```
 
 ## Dependencies with other dependencies
 
 If you're adding an object with dependencies, declare it as a
 `private(set) lazy var`. Then you can reference `self`.
 ```swift
 private(set) lazy var viewTracker: ViewTracker = ViewTracker(deps: self)
 ```
 
 ## Dependencies with public config
 
 If you're exposing a class for use in `ModuleConfig`, declare a second
 private property to hold the specialization from the module. Then
 declare the dependency property as a `private(set) lazy var` that checks
 the specialization, and then provides a default implementation.
 ```swift
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
 ```
 
 ## Computed dependencies
 
 Use a normal computed property for these.
 ```swift
 var clientConfig: ClientConfig {
   clientConfigService.config
 }
 ```

 # Testing
 
 If you need to use these dependencies in a unit test, see `TestModule`
 and `ModuleTestCase`.
 */
final class Module: AllDeps {
  private(set) lazy var analytics: Analytics? =
    analyticsConnection != nil ? Analytics(deps: self) : nil

  private(set) var analyticsConnection: AnalyticsConnection?

  var clientConfig: ClientConfig {
    clientConfigService.config
  }

  private(set) lazy var clientConfigService: ClientConfigService =
    clientConfigServiceSpec ?? LocalClientConfigService(initialConfig: initialConfig)
  private let clientConfigServiceSpec: ClientConfigService?

  let clock: Clock = SystemClock()
  
  let deviceInfo: DeviceInfo = IOSDeviceInfo()
  
  let idMap: IDMap = DefaultIDMap()
  
  let initialConfig: ClientConfig

  private(set) lazy var networkConnection: NetworkConnection = {
    assert(networkConnectionSpec != nil, "Missing NetworkConnection")
    return networkConnectionSpec ?? NoOpNetworkConnection()
  } ()
  private let networkConnectionSpec: NetworkConnection?

  let operationMonitor = OperationMonitor()

  func osLog(category: String) -> OSLog? {
    osLogSource?.osLog(category: category)
  }

  private(set) lazy var osLogSource: OSLogSource? =
    clientConfig.osLogLevel > .none ? SystemOSLogSource(deps: self) : nil

  private(set) lazy var persistentStore: PersistentStore =
    persistentStoreSpec ?? UserDefaultsPersistentStore()
  private let persistentStoreSpec: PersistentStore?

  let uiState: UIState = UIKitState()

  private(set) lazy var viewTracker: ViewTracker = ViewTracker(deps: self)

  private(set) lazy var xray: Xray? =
    (clientConfig.xrayLevel > .none || clientConfig.diagnosticsIncludeBatchSummaries) ?
    Xray(deps: self) : nil

  convenience init(moduleConfig: ModuleConfig) {
    self.init(initialConfig: moduleConfig.initialConfig,
              analyticsConnection: moduleConfig.analyticsConnection,
              clientConfigService: moduleConfig.clientConfigService,
              networkConnection: moduleConfig.networkConnection,
              persistentStore: moduleConfig.persistentStore)
  }

  init(initialConfig: ClientConfig,
       analyticsConnection: AnalyticsConnection? = nil,
       clientConfigService: ClientConfigService? = nil,
       networkConnection: NetworkConnection? = nil,
       persistentStore: PersistentStore? = nil) {
    self.initialConfig = ClientConfig(initialConfig)
    self.analyticsConnection = analyticsConnection
    self.clientConfigServiceSpec = clientConfigService
    self.networkConnectionSpec = networkConnection
    self.persistentStoreSpec = persistentStore
  }

  /// Loads all dependencies from `ModuleConfig`. Ensures that any
  /// runtime errors occur early on in initialization.
  func validateModuleConfigDependencies() throws {
    if networkConnectionSpec == nil {
      throw ModuleConfigError.missingNetworkConnection
    }
  }

  /// Starts any services among dependencies.
  func startLoggingServices() throws {
    _ = analytics
    try analyticsConnection?.startServices()
    try clientConfigService.fetchClientConfig()
    // Initialize Xray as an OperationMonitorListener.
    _ = xray
  }
}

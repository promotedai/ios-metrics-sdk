import Foundation

// MARK: - ClientConfig properties
/**
 Configuration for Promoted logging library internal behavior.
 See `ClientConfigService` for information about how these
 configs are loaded.

 This struct should only contain properties that apply to the
 Promoted logging library in general. Mechanisms that alter
 the way that client code calls the Promoted logging library
 should go in client code, external from this config.

 # Objective C interoperability

 The Objective C interoperability of this struct is contained
 in a class called `_ObjCClientConfig`. Use that class only in
 Objective C (where it's named `PROClientConfig`).

 We chose to make this separate class for the following reasons.

 1. `ClientConfig` makes most sense as a struct in Swift, since
    its semantics are always pass-by-value:
    a. Attempting to maintain this as a class in Swift can lead
       to hard-to-catch issues when forgetting to copy.
    b. We need to make `ClientConfig` immutable after logging
       services are started. Structs can be made read-only
       easily because they are pass-by-value.
 2. Objective C can't work with Swift structs, only classes.
 3. The extra code needed to maintain this bridge can be tested,
    but it's much harder to test for mis-uses of `ClientConfig`
    as a class.

 # Adding new properties.

 When adding a new property, do the following:

 1. Ensure the type is `Codable` and can be expressed in
    Objective C. If you're adding a new enum type as well,
    see the next section.
 2. Add a property of same name and type in
    `_ObjCClientConfig`.
 3. Add the property to the `allKeyPaths` map.
 4. If you added a new type that isn't covered by the switch
    statements in `value(forName name: String)` and
    `setValue(_ value: Any, forName name: String)`, add the
    type in both switch statements.

 # Adding new enums

 When adding a new enum property, do the following:

 1. Make the type and value public.
 2. Make the type `@objc` and give it a name prefixed with `PRO`.
    The type will be referenced from `_ObjCClientConfig`.
 3. Make it an `Int` enum.
 4. Make it conform to `ConfigEnum`.
 5. Add an extension that contains `var description`.

 The final three items ensure that it works with remote config
 and serialization.

 Example:
 ```swift
 @objc(PROAlohaEnum)
 public enum AlohaEnum: Int, ConfigEnum {
   case hello = 1
   case goodbye = 2
 }
 @objc public var aloha: AlohaEnum = .hello

 extension ClientConfig.AlohaEnum {
   public var description: String {
     switch self {
     case .hello:
       return "hello"
     case .goodbye:
       return "goodbye"
     default:
       return "unknown"
   }
 }
 ```

 # Validation

 When adding new properties that are numerical or enum values,
 make sure to validate in `didSet` to ensure that incorrect
 values don't cause unreasonable behavior during runtime. See
 `bound` and `validateEnum`.
 */
@dynamicMemberLookup
public struct ClientConfig {

  public typealias MetricsLoggingWireFormat =
    _ObjCClientConfig.MetricsLoggingWireFormat
  public typealias XrayLevel = _ObjCClientConfig.XrayLevel
  public typealias OSLogLevel = _ObjCClientConfig.OSLogLevel

  private var config: _ObjCClientConfig = _ObjCClientConfig()

  public subscript<T>(
    dynamicMember keyPath: WritableKeyPath<_ObjCClientConfig, T>
  ) -> T {
    get { config[keyPath: keyPath] }
    set {
      ensureConfigUniquelyReferenced()
      config[keyPath: keyPath] = newValue
    }
  }

  public func value(forKey key: String) -> Any? {
    config.value(forKey: key)
  }

  public mutating func setValue(_ value: Any?, forKey key: String) {
    ensureConfigUniquelyReferenced()
    config.setValue(value, forKey: key)
  }

  private mutating func ensureConfigUniquelyReferenced() {
    if !isKnownUniquelyReferenced(&config) {
      config = _ObjCClientConfig(config)
    }
  }

  public init() {}

  public init(_ config: _ObjCClientConfig) {
    self.config = config
  }
}

// MARK: - Codable
extension ClientConfig: Codable {}

// MARK: - CustomReflectable
extension ClientConfig: CustomReflectable {
  public var customMirror: Mirror { Mirror(reflecting: config) }
}

// MARK: - Internal
extension ClientConfig {

  var anyDiagnosticsEnabled: Bool { config.anyDiagnosticsEnabled }

  func validateConfig() throws {
    try config.validateConfig()
  }
}

// MARK: - Testing
extension ClientConfig {
  mutating func disableAssertInValidationForTesting() {
    config.disableAssertInValidationForTesting()
  }
}

// MARK: - Protocol composition
protocol InitialConfigSource {
  var initialConfig: ClientConfig { get }
}

protocol ClientConfigSource: InitialConfigSource {
  var clientConfig: ClientConfig { get }
}

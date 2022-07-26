import Foundation

// MARK: - ClientConfig properties
/**
 Configuration for Promoted logging library internal behavior.
 See `ClientConfigService` for information about how these
 configs are loaded.

 `ClientConfig` should only contain properties that apply to the
 Promoted logging library in general. Mechanisms that alter
 the way that client code calls the Promoted logging library
 should go in client code, external from this config.

 Properties should be added in `_ObjCClientConfig`. See that
 class for instructions.

 # Objective C interoperability

 This struct wraps a class called `_ObjCClientConfig`.
 (Objective C can only use Swift classes, not structs.) The
 underlying storage for all properties lies in that class. This
 struct uses key paths to manage property access so that all
 properties in the class are directly accessible via this
 struct.

 Furthermore, `ClientConfig` uses copy-on-write to preserve
 pass-by-value semantics for structs. That is, if you make a
 copy of this struct and modify the copy, the original remains
 unchanged.

 The drawback of this approach is that, even though Swift code
 should only interact with this struct, config properties all
 need to go in `_ObjCClientConfig` instead of here. Still, this
 approach gives us our desired behavior with minimal boilerplate
 code, so it's still worth it.
 */
@dynamicMemberLookup
public struct ClientConfig {

  public typealias MetricsLoggingWireFormat =
    _ObjCClientConfig.MetricsLoggingWireFormat
  public typealias XrayLevel = _ObjCClientConfig.XrayLevel
  public typealias OSLogLevel = _ObjCClientConfig.OSLogLevel
  public typealias MetricsLoggingErrorHandling =
    _ObjCClientConfig.MetricsLoggingErrorHandling

  private var config: _ObjCClientConfig

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

  /// Enforces copy-on-write of underlying ObjC config.
  /// Make sure to call this at the start of every mutating
  /// method.
  private mutating func ensureConfigUniquelyReferenced() {
    if !isKnownUniquelyReferenced(&config) {
      config = _ObjCClientConfig(config)
    }
  }

  public init() {
    self.config = _ObjCClientConfig()
  }

  public init(_ config: _ObjCClientConfig) {
    self.config = _ObjCClientConfig(config)
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
  mutating func setAllDiagnosticsEnabled(_ enabled: Bool) {
    ensureConfigUniquelyReferenced()
    config.setAllDiagnosticsEnabled(enabled)
  }

  var diagnosticsSamplingEndDate: Date? {
    return config.diagnosticsSamplingEndDate
  }

  func validateConfig() throws {
    try config.validateConfig()
  }
}

// MARK: - Testing
extension ClientConfig {
  mutating func disableAssertInValidationForTesting() {
    ensureConfigUniquelyReferenced()
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

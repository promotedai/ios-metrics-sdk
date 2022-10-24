#if canImport(CryptoKit)
import CryptoKit
#endif
import Firebase
import Foundation

#if SWIFT_PACKAGE
import FirebaseRemoteConfig
import PromotedCore
#endif

extension ClientConfig {

  mutating func merge(
    from remoteConfig: RemoteConfig,
    messages: inout PendingLogMessages
  ) {
    var dictionary: [String: String] = [:]
    for key in remoteConfig.allKeys(from: .remote) {
      dictionary[key] = remoteConfig.configValue(forKey: key).stringValue
    }
    merge(from: dictionary, messages: &messages)
  }

  mutating func merge(
    from dictionary: [String: String],
    messages: inout PendingLogMessages
  ) {
    var remainingKeys = Set(dictionary.keys)
    let mirror = Mirror(reflecting: self)

    // It's much safer to iterate over all keys in ClientConfig,
    // even though the dictionary should only contain a subset of
    // these keys.
    // If we pass a non-existent key to NSObject.setValue(), it
    // throws an ObjC exception that we can't catch in Swift.
    // This could cause a runtime crash.
    // Iterating through ClientConfig's keys ensures that the keys
    // we pass to setValue are valid.
    for child in mirror.children {
      let optionalChildLabel = child.label
      // `assertInValidation` is a local debugging flag.
      if optionalChildLabel == "assertInValidation" { continue }
      guard let childLabel = optionalChildLabel else {
        messages.warning(
          "Child with no label: \(String(describing: child))",
          visibility: .public
        )
        continue
      }

      let key = "ai_promoted_" + childLabel.toSnakeCase()
      let optionalRemoteValue = dictionary[key]

      // The value might not be overridden in remote config.
      // This isn't a warning. Just ignore.
      guard let remoteValue = optionalRemoteValue else { continue }
      remainingKeys.remove(key)

      guard let convertedValue = convertedValue(
        forRemoteValue: remoteValue, child: child
      ) else {
        messages.warning(
          "No viable conversion for remote config value: " +
            "\(key) = \(String(describing: remoteValue)) (ignoring)",
          visibility: .public
        )
        continue
      }

      let consoleValue = valueToConsoleLog(
        forChildLabel: childLabel,
        convertedValue: convertedValue
      )
      messages.info(
        "Read from remote config: \(key) = \(consoleValue)",
        visibility: .public
      )

      self.setValue(convertedValue, forKey: childLabel)
      checkValidatedValueChanged(
        label: childLabel,
        dictionaryKey: key,
        convertedValue: convertedValue,
        messages: &messages
      )
    }

    for remainingKey in remainingKeys {
      messages.warning(
        "Unrecognized key in remote config: \(remainingKey) (ignoring)"
      )
    }
  }

  private func convertedValue(
    forRemoteValue remoteValue: String,
    child: Mirror.Child
  ) -> Any? {
    switch child.value {
    case is Int:
      return Int(remoteValue)
    case is Double:
      return Double(remoteValue)
    case is Bool:
      return Bool(remoteValue)
    case is String:
      return remoteValue
    case is [String: String]:
      guard let data = remoteValue.data(using: .utf8) else { return nil }
      return try? JSONSerialization.jsonObject(with: data, options: [])
    case is ClientConfig.MetricsLoggingWireFormat:
      return ClientConfig.MetricsLoggingWireFormat(remoteValue.toCamelCase())
    case is ClientConfig.XrayLevel:
      return ClientConfig.XrayLevel(remoteValue.toCamelCase())
    case is ClientConfig.OSLogLevel:
      return ClientConfig.OSLogLevel(remoteValue.toCamelCase())
    default:
      return nil
    }
  }

  private func checkValidatedValueChanged<Value>(
    label: String,
    dictionaryKey: String,
    convertedValue: Value,
    messages: inout PendingLogMessages
  ) {
    guard let validatedValue = value(forKey: label) else {
      messages.warning(
        "Could not read value for property: \(label)",
        visibility: .public
      )
      return
    }
    if !AnyHashable.areEqual(convertedValue, validatedValue) {
      messages.warning(
        "Attempted to set invalid value: " +
          "\(dictionaryKey) = \(convertedValue) " +
          "(using \(validatedValue) instead)",
        visibility: .public
      )
    }
  }

  /// When console logging certain sensitive values, we don't
  /// want to echo the exact value where anyone can inspect it.
  ///
  /// In these cases, it's  likely that we already know the
  /// expected value, so we output the SHA-256 hash instead.
  ///
  /// You can compute SHA-256 values for strings here:
  /// https://emn178.github.io/online-tools/sha256.html
  private func valueToConsoleLog(
    forChildLabel label: String,
    convertedValue: Any
  ) -> String {
    switch label {
    case "metricsLoggingURL",
         "metricsLoggingAPIKey",
         "devMetricsLoggingURL",
         "devMetricsLoggingAPIKey":
      #if canImport(CryptoKit)
      if #available(iOS 13, *),
         let value = convertedValue as? String {
        let hash = SHA256.hash(data: Data(value.utf8))
        // We don't need to echo the whole digest, only enough
        // to confirm if this equals a known value's hash.
        let prefix = hash.prefix(8).map { String(format: "%02x", $0) }.joined()
        return "<<sha256: \(prefix)…>>"
      }
      #endif
      return "<<private>>"
    default:
      return String(describing: convertedValue)
    }
  }
}

extension String {
  func toSnakeCase() -> String {
    let aA = try! NSRegularExpression(
      pattern: "([a-z])([A-Z])", options: []
    )
    var range = NSRange(location: 0, length: count)
    var result = aA.stringByReplacingMatches(
      in: self,
      options: [],
      range: range,
      withTemplate: "$1_$2"
    )
    let AAa = try! NSRegularExpression(
      pattern: "([A-Z])([A-Z])([a-z])", options: []
    )
    range = NSRange(location: 0, length: result.count)
    result = AAa.stringByReplacingMatches(
      in: result,
      options: [],
      range: range,
      withTemplate: "$1_$2$3"
    )
    return result.lowercased()
  }

  func toCamelCase() -> String {
    return split(separator: "_")
      .enumerated()
      .map { (index, str) in
        (index == 0) ? str : (str.prefix(1).uppercased() + str.dropFirst())
      }
      .joined()
  }
}

extension Equatable {
  static func areEqual(_ a: Any, _ b: Any) -> Bool {
    guard let a = a as? Self, let b = b as? Self else { return false }
    return a == b
  }
}

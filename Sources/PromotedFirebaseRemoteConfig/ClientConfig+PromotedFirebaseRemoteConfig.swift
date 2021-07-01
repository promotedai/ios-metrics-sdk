import FirebaseRemoteConfig
import Foundation

#if !COCOAPODS
import PromotedCore
#endif

extension ClientConfig {

  convenience init(
    remoteConfig: RemoteConfig,
    warnings: inout [String],
    infos: inout [String]
  ) {
    self.init()
    var remainingKeys = Set(remoteConfig.allKeys(from: .remote))
    let mirror = Mirror(reflecting: self)
    for child in mirror.children {
      guard let key = child.label?.toSnakeCase() else {
        warnings.append(
          "Child with no label: \(String(describing: child))"
        )
        continue
      }

      let remoteValue = remoteConfig.configValue(
        forKey: key, source: .remote
      )

      // The value may not be overridden in remote config.
      // This isn't a warning. Just ignore.
      guard remoteValue.stringValue != nil else { continue }
      guard let convertedValue = convertedValue(
        forRemoteValue: remoteValue, child: child
      ) else {
        warnings.append(
          "No viable conversion for remote config value: " +
            "\(key) = \(String(describing: remoteValue))"
        )
        continue
      }

      infos.append(
        "Read from remote config: " +
          "\(key) = \(String(describing: convertedValue))"
      )

      self.setValue(convertedValue, forKey: key)
      checkValidatedValueChanged(
        key: key,
        dictValue: convertedValue,
        warnings: &warnings
      )
      remainingKeys.remove(key)
    }
    for remainingKey in remainingKeys {
      warnings.append("Unused key in remote config: \(remainingKey)")
    }
  }

  private func convertedValue(
    forRemoteValue remoteValue: RemoteConfigValue,
    child: Mirror.Child
  ) -> Any? {
    switch child.value {
    case is Int:
      return remoteValue.numberValue.intValue
    case is Double:
      return remoteValue.numberValue.doubleValue
    case is Bool:
      return remoteValue.boolValue
    case is String:
      return remoteValue.stringValue
    case is ClientConfig.MetricsLoggingWireFormat:
      return ClientConfig.MetricsLoggingWireFormat(
        stringLiteral: remoteValue.stringValue!
      )
    case is ClientConfig.XrayLevel:
      return ClientConfig.XrayLevel(
        stringLiteral: remoteValue.stringValue!
      )
    case is ClientConfig.OSLogLevel:
      return ClientConfig.OSLogLevel(
        stringLiteral: remoteValue.stringValue!
      )
    default:
      return nil
    }
  }

  private func checkValidatedValueChanged(
    key: String,
    dictValue: Any,
    warnings: inout [String]
  ) {
    if let validatedValue = value(forKey: key),
       !AnyHashable.areEqual(dictValue, validatedValue) {
      warnings.append(
        "Attempted to set invalid value:\(key) = \(dictValue) " +
          "(using \(validatedValue) instead)"
      )
    }
  }
}

extension String {
  func toSnakeCase() -> String {
    let aA = try! NSRegularExpression(pattern: "[a-z][A-Z]", options: [])
    var range = NSRange(location: 0, length: count)
    var result = aA.stringByReplacingMatches(in: self, options: [], range: range, withTemplate: "$1_$2")
    let AAa = try! NSRegularExpression(pattern: "[A-Z][A-Z][a-z]", options: [])
    range = NSRange(location: 0, length: result.count)
    result = AAa.stringByReplacingMatches(in: result, options: [], range: range, withTemplate: "$1_$2$3")
    return result.lowercased()
  }
}

extension Equatable {
  static func areEqual(_ a: Any, _ b: Any) -> Bool {
    guard let a = a as? Self, let b = b as? Self else { return false }
    return a == b
  }
}

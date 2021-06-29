import FirebaseRemoteConfig
import Foundation

#if !COCOAPODS
import PromotedCore
#endif

extension ClientConfig {

  convenience init(remoteConfig: RemoteConfig,
                   warnings: inout [String]?,
                   infos: inout [String]?) {
    self.init()
    var remainingKeys = Set(remoteConfig.allKeys(from: .remote))
    let mirror = Mirror(reflecting: self)
    for var child in mirror.children {
      guard let key = child.label?.toSnakeCase() else {
        warnings?.append("Child with no label: \(String(describing: child))")
        continue
      }
      let value = remoteConfig.configValue(forKey: key, source: .remote)
      guard let stringValue = value.stringValue else { continue }
      infos?.append("Read from remote config: \(key) = \(String(describing: stringValue))")
      remainingKeys.remove(key)
      child.value = value
    }
    for remainingKey in remainingKeys {
      warnings?.append("Unused key in remote config: \(remainingKey)")
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

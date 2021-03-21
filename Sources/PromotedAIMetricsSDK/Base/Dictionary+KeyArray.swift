import Foundation

public extension Dictionary where Key == String {
  /// Returns the first value present in the dictionary from
  /// `keyArray`.
  func firstValueFromKeysInArray(_ keyArray: [Key]) -> String? {
    for key in keyArray {
      if let value = self[key] as? String {
        return value
      }
    }
    return nil
  }
}

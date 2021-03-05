import Foundation

// MARK: -
/** Stores information between invocations of the app. */
public protocol PersistentStore: class {
  
  /// User ID of last signed-in user. `nil` if user was signed out.
  var userID: String? { get set }
  
  /// Log user ID of last signed-in or signed-out user.
  var logUserID: String? { get set }
}

// MARK: -
/** Stores information in the app's `UserDefaults`. */
class UserDefaultsPersistentStore: PersistentStore {
  
  enum UserDefaultKey: String {
    case userIDString
    case logUserIDString
  }
  
  var userID: String? {
    get {
      return stringValue(forKey: .userIDString)
    }
    set(value) {
      setStringValue(value, forKey: .userIDString)
    }
  }

  var logUserID: String? {
    get {
      return stringValue(forKey: .logUserIDString)
    }
    set(value) {
      setStringValue(value, forKey: .logUserIDString)
    }
  }

  private let defaults: UserDefaults
  
  init(userDefaults: UserDefaults = UserDefaults.standard) {
    self.defaults = userDefaults
  }
  
  private func stringValue(forKey key: UserDefaultKey) -> String? {
    return defaults.string(forKey: "ai.promoted." + key.rawValue)
  }
  
  private func setStringValue(_ value: String?, forKey key: UserDefaultKey) {
    defaults.setValue(value, forKey: "ai.promoted." + key.rawValue)
  }
}

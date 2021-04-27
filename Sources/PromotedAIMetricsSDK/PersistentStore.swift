import Foundation

// MARK: -
/** Stores information between invocations of the app. */
public protocol PersistentStore: class {
  
  /// User ID of last signed-in user. `nil` if user was signed out.
  var userID: String? { get set }
  
  /// Log user ID of last signed-in or signed-out user.
  var logUserID: String? { get set }
}

public protocol PersistentStoreProvider {
  var persistentStore: PersistentStore { get }
}

// MARK: -
/** Stores information in the app's `UserDefaults`. */
final class UserDefaultsPersistentStore: PersistentStore {
  
  var userID: String? {
    get { stringValue(forKey: #function) }
    set(value) { setStringValue(value, forKey: #function) }
  }

  var logUserID: String? {
    get { stringValue(forKey: #function) }
    set(value) { setStringValue(value, forKey: #function) }
  }

  private let defaults: UserDefaults
  
  init(userDefaults: UserDefaults = UserDefaults.standard) {
    self.defaults = userDefaults
  }
  
  private func stringValue(forKey key: String) -> String? {
    defaults.string(forKey: "ai.promoted." + key)
  }
  
  private func setStringValue(_ value: String?, forKey key: String) {
    defaults.setValue(value, forKey: "ai.promoted." + key)
  }
}

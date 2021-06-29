import Foundation

// MARK: -
/** Stores information between invocations of the app. */
public protocol PersistentStore: AnyObject {
  
  /// User ID of last signed-in user. `nil` if user was signed out.
  var userID: String? { get set }
  
  /// Log user ID of last signed-in or signed-out user.
  var logUserID: String? { get set }

  /// Locally cached client config.
  var clientConfig: [String: Any]? { get set }
}

protocol PersistentStoreSource {
  var persistentStore: PersistentStore { get }
}

// MARK: -
/** Stores information in the app's `UserDefaults`. */
final class UserDefaultsPersistentStore: PersistentStore {
  
  var userID: String? {
    get { stringValue(forKey: #function) }
    set(value) { setValue(value, forKey: #function) }
  }

  var logUserID: String? {
    get { stringValue(forKey: #function) }
    set(value) { setValue(value, forKey: #function) }
  }

  var clientConfig: [String : Any]? {
    get { dictionaryValue(forKey: #function) }
    set(value) { setValue(value, forKey: #function) }
  }

  private let defaults: UserDefaults
  
  init(userDefaults: UserDefaults = UserDefaults.standard) {
    self.defaults = userDefaults
  }
  
  private func stringValue(forKey key: String) -> String? {
    defaults.string(forKey: "ai.promoted." + key)
  }

  private func dictionaryValue(forKey key: String) -> [String: Any]? {
    defaults.dictionary(forKey: "ai.promoted." + key)
  }

  private func setValue(_ value: Any?, forKey key: String) {
    defaults.setValue(value, forKey: "ai.promoted." + key)
  }
}

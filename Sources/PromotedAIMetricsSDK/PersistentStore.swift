import Foundation

@objc(PROPersistentStore)
public protocol PersistentStore: class {
  var userID: String? { get set }
  var logUserID: String? { get set }
  var clientConfigMessage: Data? { get set }
}

@objc(PROUserDefaultsPersistentStore)
public class UserDefaultsPersistentStore: NSObject, PersistentStore {
  
  enum UserDefaultKey: String {
    case userIDString
    case logUserIDString
    case clientConfigMessageData
  }
  
  public var userID: String? {
    get {
      return defaults.string(forKey: UserDefaultKey.userIDString.rawValue)
    }
    set(value) {
      defaults.setValue(value, forKey: UserDefaultKey.userIDString.rawValue)
    }
  }

  public var logUserID: String? {
    get {
      return defaults.string(forKey: UserDefaultKey.logUserIDString.rawValue)
    }
    set(value) {
      defaults.setValue(value, forKey: UserDefaultKey.logUserIDString.rawValue)
    }
  }
  
  public var clientConfigMessage: Data? {
    get {
      return defaults.data(forKey: UserDefaultKey.clientConfigMessageData.rawValue)
    }
    set(value) {
      defaults.setValue(value, forKey: UserDefaultKey.clientConfigMessageData.rawValue)
    }
  }

  private let defaults: UserDefaults
  
  @objc public init(userDefaults: UserDefaults = UserDefaults.standard) {
    self.defaults = userDefaults
  }
}

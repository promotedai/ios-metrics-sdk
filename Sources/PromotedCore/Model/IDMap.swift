import Foundation

// MARK: -
/** Maps client-side IDs to server-side IDs. */
protocol IDMap {

  /// Generates a log user ID which is used to track the the current
  /// session without exposing the underlying user ID.
  func logUserID() -> String
  
  /// Generates a new session ID.
  func sessionID() -> String

  /// Generates a new impression ID.
  func impressionID() -> String

  /// Given a client's content ID, generates a content ID to log.
  func contentID(clientID: String) -> String

  /// Generates a new click ID.
  func actionID() -> String
  
  /// Generates a new view ID.
  /// Returns the null UUID string when passed `nil`.
  func viewID() -> String
}

protocol IDMapSource {
  var idMap: IDMap { get }
}

// MARK: -
final class DefaultIDMap: IDMap {

  func logUserID() -> String { UUID().uuidString }
  
  func sessionID() -> String { UUID().uuidString }

  func impressionID() -> String { UUID().uuidString }
  
  func contentID(clientID: String) -> String { clientID }
  
  func actionID() -> String { UUID().uuidString }
  
  func viewID() -> String { UUID().uuidString }
}

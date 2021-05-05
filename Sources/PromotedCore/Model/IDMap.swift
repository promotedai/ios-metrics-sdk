import CommonCrypto
import Foundation

// MARK: -
/** Maps client-side IDs to server-side IDs. */
protocol IDMap {
  
  /// Produces a deterministic UUID string given an input value.
  /// Collision of returned values when given different input should
  /// be the same as generating new UUIDs. The generated UUIDs are
  /// not necessarily cryptographically secure.
  func deterministicUUIDString(value: String?) -> String

  /// Given a client-side user ID, generates a log user ID which
  /// is used to track the the current session without exposing
  /// the underlying user ID.
  func logUserID() -> String
  
  /// Generates a new session ID.
  func sessionID() -> String

  /// Given possible input sources, generate a server-side impression ID.
  /// If `insertionID` is not `nil`, then generates an impression ID based
  /// on `insertionID`. If `contentID` and `logUserID` are both not `nil`,
  /// then generates an impression ID based on a combination of those two
  /// IDs. Otherwise, returns `nil`.
  func impressionIDOrNil(insertionID: String?,
                         contentID: String?,
                         logUserID: String?) -> String?

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
/**
 DO NOT INSTANTIATE. Base class for IDMap implementation.
 The `impressionID(clientID:)` and `logUserID(userID:)` methods would
 ideally be in the protocol extension, but doing so prevents
 FakeIDMap from overriding them for tests.
 */
class AbstractIDMap: IDMap {

  init() {}

  func deterministicUUIDString(value: String?) -> String {
    assertionFailure("Don't instantiate AbstractIDMap")
    return ""
  }

  func logUserID() -> String { UUID().uuidString }
  
  func sessionID() -> String { UUID().uuidString }

  func impressionIDOrNil(insertionID: String?,
                              contentID: String?,
                              logUserID: String?) -> String? {
    if let insertionID = insertionID {
      return deterministicUUIDString(value: insertionID)
    }
    if let contentID = contentID, let logUserID = logUserID {
      let combined = contentID + logUserID
      return deterministicUUIDString(value: combined)
    }
    return nil
  }
  
  func contentID(clientID: String) -> String { clientID }
  
  func actionID() -> String { UUID().uuidString }
  
  func viewID() -> String { UUID().uuidString }
}

// MARK: -
/** SHA1-based deterministic UUID generation. */
final class SHA1IDMap: AbstractIDMap {
  
  override func deterministicUUIDString(value: String?) -> String {
    if let s = value { return SHA1IDMap.sha1(s) }
    return "00000000-0000-0000-0000-000000000000"
  }

  static func sha1(_ value: String) -> String {
    var context = CC_SHA1_CTX()
    CC_SHA1_Init(&context)
    _ = value.withCString { (cString) in
      CC_SHA1_Update(&context, cString, CC_LONG(strlen(cString)))
    }
    var array = [UInt8](repeating: 0, count: Int(CC_SHA1_DIGEST_LENGTH))
    CC_SHA1_Final(&array, &context)
    array[6] = (array[6] & 0x0F) | 0x50 // set version number nibble to 5
    array[8] = (array[8] & 0x3F) | 0x80 // reset clock nibbles
    let uuid = UUID(uuid: (array[0], array[1], array[2], array[3],
                           array[4], array[5], array[6], array[7],
                           array[8], array[9], array[10], array[11],
                           array[12], array[13], array[14], array[15]))
    return uuid.uuidString
  }
}

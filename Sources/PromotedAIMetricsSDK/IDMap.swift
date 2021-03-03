import CommonCrypto
import Foundation

public protocol IDMap {
  func deterministicUUIDString(value: String) -> String
}

public extension IDMap {
  func impressionID(clientID: String) -> String {
    return deterministicUUIDString(value: clientID)
  }
}

public class SHA1IDMap: IDMap {
  
  public static let instance = SHA1IDMap()
  
  private init() {}
  
  public func deterministicUUIDString(value: String) -> String {
    return SHA1IDMap.sha1(value)
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

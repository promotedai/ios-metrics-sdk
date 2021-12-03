import Foundation

extension UUID {
  /// Generates a hash value that is stable across invocations
  /// of the process. (In general, hash values in Swift aren't
  /// stable when you restart the process.)
  var stableHashValue: UInt32 {
    let a = self.uuid
    return (UInt32(a.7) << 8) | UInt32(a.15)
  }

  /// Computes stable hash value over given modulus.
  func stableHashValueMod(_ modulus: UInt32) -> UInt32 {
    return stableHashValue % modulus
  }
}

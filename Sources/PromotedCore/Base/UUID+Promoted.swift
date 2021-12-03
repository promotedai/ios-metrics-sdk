import Foundation

extension UUID {
  /// Generates a hash value that is stable across invocations
  /// of the process. (In general, hash values in Swift aren't
  /// stable, including UUID's hash value.)
  var stableHashValue: UInt64 {
    let a = self.uuid
    return (
      UInt64(a.0 << 56) |
      UInt64(a.2 << 48) |
      UInt64(a.4 << 40) |
      UInt64(a.6 << 32) |
      UInt64(a.8 << 24) |
      UInt64(a.10 << 16) |
      UInt64(a.12 << 8) |
      UInt64(a.14)
    )
  }

  /// Computes stable hash value over given modulus.
  func stableHashValueMod(_ modulus: UInt) -> UInt {
    return UInt(stableHashValue % UInt64(modulus))
  }
}

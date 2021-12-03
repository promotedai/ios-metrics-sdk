import Foundation

extension UUID {
  /// Generates a hash value that is stable across invocations
  /// of the process. (In general, hash values in Swift aren't
  /// stable across different runs of the process.)
  var stableHashValue: (UInt64, UInt64) {
    let a = self.uuid
    let hi = (
      UInt64(a.0 << 56) |
      UInt64(a.1 << 48) |
      UInt64(a.2 << 40) |
      UInt64(a.3 << 32) |
      UInt64(a.4 << 24) |
      UInt64(a.5 << 16) |
      UInt64(a.6 << 8) |
      UInt64(a.7)
    )
    let lo = (
      UInt64(a.8 << 56) |
      UInt64(a.9 << 48) |
      UInt64(a.10 << 40) |
      UInt64(a.11 << 32) |
      UInt64(a.12 << 24) |
      UInt64(a.13 << 16) |
      UInt64(a.14 << 8) |
      UInt64(a.15)
    )
    return (hi, lo)
  }

  /// Computes stable hash value over given modulus.
  func stableHashValueMod(_ modulus: UInt32) -> UInt32 {
    let (hi, lo) = stableHashValue
    let mod64 = UInt64(modulus)
    let max64mod = UInt64.max % mod64
    return UInt32((
      ((hi % mod64) * (max64mod)) + (lo % mod64)
    ) % mod64)
  }
}

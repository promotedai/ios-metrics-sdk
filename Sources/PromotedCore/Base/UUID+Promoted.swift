import Foundation

extension UUID {
  /// Generates a hash value that is stable across invocations
  /// of the process. (In general, hash values in Swift aren't
  /// stable across different runs of the process.)
  ///
  /// # Machine-dependent results
  /// Casts the UUID struct (128 bits) into a pair of UInt64s.
  ///
  /// As an implementation detail, the results of this cast could
  /// vary depending on whether the CPU is big- or little-endian.
  /// Although Apple's iOS devices run in little-endian as of
  /// 2021Q4, software should not rely on this behavior.
  ///
  /// The even distribution of hash values across buckets has been 
  /// verified on both big- and little-endian environments.
  private var stableHashValue: (UInt64, UInt64) {
    withUnsafePointer(to: uuid) { p in
      p.withMemoryRebound(
        to: UInt64.self,
        capacity: MemoryLayout<UInt64>.size
      ) { ui64p in (ui64p[0], ui64p[1]) }
    }
  }

  /// Computes stable hash value over given modulus. This is
  /// primarily used to cohort users by some UUID. If the UUIDs
  /// themselves are random, then the values of this method
  /// will also be evenly distributed across all cohorts.
  func stableHashValue(mod: UInt32) -> UInt32 {
    let (hi, lo) = stableHashValue
    let mod64 = UInt64(mod)
    let max64mod = UInt64.max % mod64
    let result = ((hi % mod64) * max64mod) + (lo % mod64)
    return UInt32(result % mod64)
  }
}

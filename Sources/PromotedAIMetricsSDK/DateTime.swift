import Foundation

func MetricsTimestamp() -> UInt64 {
  return UInt64(Date().timeIntervalSince1970 * 1000)
}

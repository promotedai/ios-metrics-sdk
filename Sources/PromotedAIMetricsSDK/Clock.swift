import Foundation

public protocol Clock {
  var now: TimeInterval { get }
}

public extension Clock {
  var nowMillis: UInt64 {
    return UInt64(now * 1000)
  }
}

public class SystemClock: Clock {
  public init() {}
  public var now: TimeInterval {
    return Date().timeIntervalSince1970
  }
}

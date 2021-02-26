import Foundation

@objc(PROClock)
public protocol Clock {
  var now: TimeInterval { get }
}

public extension Clock {
  var nowMillis: UInt64 {
    return UInt64(now * 1000)
  }
}

@objc(PROSystemClock)
public class SystemClock: NSObject, Clock {
  public override init() {}
  public var now: TimeInterval {
    return Date().timeIntervalSince1970
  }
}

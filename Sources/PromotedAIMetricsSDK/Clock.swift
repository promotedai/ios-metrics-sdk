import Foundation

public protocol ScheduledTimer {}

public protocol Clock {
  var now: TimeInterval { get }
  
  typealias Callback = (Clock) -> Void
  
  func schedule(timeInterval: TimeInterval, callback: @escaping Callback) -> ScheduledTimer?
  
  func cancel(scheduledTimer: ScheduledTimer)
}

extension Clock {
  
  typealias TimeIntervalMillis = UInt64
  
  var nowMillis: TimeIntervalMillis {
    return TimeIntervalMillis(now * 1000)
  }
  
  func schedule(timeIntervalMillis: TimeIntervalMillis,
                callback: @escaping Callback) -> ScheduledTimer? {
    return schedule(timeInterval: TimeInterval(Double(timeIntervalMillis) / 1000.0),
                    callback: callback)
  }
}

public class SystemClock: NSObject, Clock {
  
  struct SystemTimer: ScheduledTimer {
    let timer: Timer
  }
  
  public static let instance = SystemClock()

  private override init() {}

  public var now: TimeInterval {
    return Date().timeIntervalSince1970
  }

  public func schedule(timeInterval: TimeInterval,
                       callback: @escaping Callback) -> ScheduledTimer? {
    guard #available(iOS 10.0, macOS 10.12, *) else { return nil }
    let timer = Timer.scheduledTimer(withTimeInterval: timeInterval, repeats: false) {_ in
      callback(self)
    }
    return SystemTimer(timer: timer)
  }

  public func cancel(scheduledTimer: ScheduledTimer) {
    guard let systemTimer = scheduledTimer as? SystemTimer else { return }
    systemTimer.timer.invalidate()
  }
}

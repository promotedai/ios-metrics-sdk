import Foundation

// MARK: -
/** Opaque type returned by `Clock.schedule()` to use when canceling. */
public protocol ScheduledTimer {}

// MARK: -
/** Represents a way to get time and perform scheduling of tasks. */
public protocol Clock {
  
  /// Returns time for use with timestamps.
  var now: TimeInterval { get }
  
  typealias TimeIntervalMillis = UInt64
  typealias Callback = (Clock) -> Void
  
  /// Schedules a callback to be invoked in the future. Callback is
  /// invoked on the main thread.
  /// Callers can capture the return value to cancel the callback.
  func schedule(timeInterval: TimeInterval, callback: @escaping Callback) -> ScheduledTimer?
  
  /// Cancels the given callback.
  func cancel(scheduledTimer: ScheduledTimer)
}

// MARK: -
extension Clock {

  var nowMillis: TimeIntervalMillis {
    return TimeIntervalMillis(now * 1000)
  }
  
  func schedule(timeIntervalMillis: TimeIntervalMillis,
                callback: @escaping Callback) -> ScheduledTimer? {
    return schedule(timeInterval: TimeInterval(Double(timeIntervalMillis) / 1000.0),
                    callback: callback)
  }
}

// MARK: -
/** Default implementation of `Clock` that deals with real time. */
class SystemClock: Clock {
  
  struct SystemTimer: ScheduledTimer {
    let timer: Timer
  }
  
  static let instance = SystemClock()

  private init() {}

  var now: TimeInterval {
    return Date().timeIntervalSince1970
  }

  func schedule(timeInterval: TimeInterval,
                callback: @escaping Callback) -> ScheduledTimer? {
    guard #available(iOS 10.0, macOS 10.12, *) else { return nil }
    let timer = Timer.scheduledTimer(withTimeInterval: timeInterval, repeats: false) {_ in
      callback(self)
    }
    return SystemTimer(timer: timer)
  }

  func cancel(scheduledTimer: ScheduledTimer) {
    guard let systemTimer = scheduledTimer as? SystemTimer else { return }
    systemTimer.timer.invalidate()
  }
}

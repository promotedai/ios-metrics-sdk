import Foundation

// MARK: -
/** Opaque type returned by `Clock.schedule()` to use when canceling. */
public protocol ScheduledTimer {}

public typealias TimeIntervalMillis = Int64

public extension TimeIntervalMillis {
  init(seconds: TimeInterval) {
    self = TimeIntervalMillis((seconds * 1000).rounded())
  }
  var seconds: TimeInterval { TimeInterval(millis: self) }
  var millis: TimeIntervalMillis { self }
}

public extension TimeInterval {
  init(millis: TimeIntervalMillis) {
    self = TimeInterval(Double(millis) / 1000.0)
  }
  var seconds: TimeInterval { self }
  var millis: TimeIntervalMillis { TimeIntervalMillis(seconds: self) }
}

// MARK: -
/** Represents a way to get time and perform scheduling of tasks. */
public protocol Clock {
  
  /// Returns time for use with timestamps or interval measurement.
  var now: TimeInterval { get }

  typealias Callback = (Clock) -> Void
  
  /// Schedules a callback to be invoked in the future. Callback is
  /// invoked on the main thread.
  /// Callers can capture the return value to cancel the callback.
  func schedule(timeInterval: TimeInterval, callback: @escaping Callback) -> ScheduledTimer?
  
  /// Cancels the given callback.
  func cancel(scheduledTimer: ScheduledTimer)
}

public protocol ClockSource {
  var clock: Clock { get }
}

// MARK: -
extension Clock {

  /// Returns time in millis for use with timestamps only.
  /// This loses sub-millisecond resolution, which makes it unsuitable
  /// for interval measurement.
  var nowMillis: TimeIntervalMillis { TimeIntervalMillis(seconds: now) }
  
  func schedule(timeIntervalMillis: TimeIntervalMillis,
                callback: @escaping Callback) -> ScheduledTimer? {
    schedule(timeInterval: TimeInterval(millis: timeIntervalMillis), callback: callback)
  }
}

// MARK: -
/** Default implementation of `Clock` that deals with real time. */
final class SystemClock: Clock {
  
  struct SystemTimer: ScheduledTimer {
    let timer: Timer
  }
  
  static let instance = SystemClock()

  private init() {}

  var now: TimeInterval { Date().timeIntervalSince1970 }

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

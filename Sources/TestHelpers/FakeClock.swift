import Foundation
import PromotedAIMetricsSDK

public class CapturedScheduledTimer: ScheduledTimer {
  public var timeInterval: TimeInterval
  public var callback: Clock.Callback
  public init(timeInterval: TimeInterval, callback: @escaping Clock.Callback) {
    self.timeInterval = timeInterval
    self.callback = callback
  }
}

public class FakeClock: Clock {

  public var now: TimeInterval
  public var scheduledTimers: [CapturedScheduledTimer]

  public init(now: TimeInterval = 0.0) {
    self.now = now
    self.scheduledTimers = []
  }
  
  public func schedule(timeInterval: TimeInterval,
                       callback: @escaping Callback) -> ScheduledTimer? {
    let timer = CapturedScheduledTimer(timeInterval: timeInterval, callback: callback)
    scheduledTimers.append(timer)
    return timer
  }
  
  public func cancel(scheduledTimer: ScheduledTimer) {
    guard let capturedTimer = scheduledTimer as? CapturedScheduledTimer else { return }
    scheduledTimers.removeAll(where: { $0 === capturedTimer })
  }
  
  public func advance(toMillis millis: TimeIntervalMillis) {
    let secs = TimeInterval(Double(millis) / 1000.0)
    advance(to: secs)
  }

  public func advance(to timeInterval: TimeInterval) {
    self.now = timeInterval
    let timersCopy = scheduledTimers
    for timer in timersCopy {
      if timer.timeInterval < timeInterval {
        scheduledTimers.removeAll(where: { $0 === timer })
        timer.callback(self)
      }
    }
  }
}

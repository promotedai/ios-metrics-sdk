import Foundation

@testable import PromotedCore

class CapturedScheduledTimer: ScheduledTimer {
  var timeInterval: TimeInterval
  var callback: Clock.Callback
  init(timeInterval: TimeInterval, callback: @escaping Clock.Callback) {
    self.timeInterval = timeInterval
    self.callback = callback
  }
}

class FakeClock: Clock {

  var now: TimeInterval
  var scheduledTimers: [CapturedScheduledTimer]

  init(now: TimeInterval = 0.0) {
    self.now = now
    self.scheduledTimers = []
  }
  
  func schedule(timeInterval: TimeInterval,
                callback: @escaping Callback) -> ScheduledTimer? {
    let timer = CapturedScheduledTimer(timeInterval: timeInterval, callback: callback)
    scheduledTimers.append(timer)
    return timer
  }
  
  func cancel(scheduledTimer: ScheduledTimer) {
    guard let capturedTimer = scheduledTimer as? CapturedScheduledTimer else { return }
    scheduledTimers.removeAll(where: { $0 === capturedTimer })
  }
  
  func advance(toMillis millis: TimeIntervalMillis) {
    let secs = TimeInterval(Double(millis) / 1000.0)
    advance(to: secs)
  }

  func advance(to timeInterval: TimeInterval) {
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

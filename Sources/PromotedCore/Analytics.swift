import Foundation

// MARK: - AnalyticsConnection
public protocol AnalyticsConnection: AnyObject {

  func log(eventCount: Int)

  func log(bytesSent: UInt64)

  func log(errors: [Error])
}

protocol AnalyticsConnectionSource {
  var analyticsConnection: AnalyticsConnection? { get }
}

// MARK: - Analytics
final class Analytics {
  private let connection: AnalyticsConnection
  private var eventCount: Int
  private var bytesToSend: UInt64
  private var errors: [Error]

  typealias Deps = AnalyticsConnectionSource & OperationMonitorSource

  init(deps: Deps) {
    self.connection = deps.analyticsConnection!
    self.eventCount = 0
    self.bytesToSend = 0
    self.errors = []
    deps.operationMonitor.addOperationMonitorListener(self)
  }

  private func flush() {
    if eventCount > 0 {
      connection.log(eventCount: eventCount)
      eventCount = 0
    }
    if bytesToSend > 0 {
      connection.log(bytesSent: bytesToSend)
      bytesToSend = 0
    }
    if !errors.isEmpty {
      connection.log(errors: errors)
      errors = []
    }
  }
}

protocol AnalyticsSource {
  var analytics: Analytics? { get }
}

extension Analytics: OperationMonitorListener {

  func executionDidEnd(context: OperationMonitor.Context) {
    if case .batchResponse = context {
      flush()
    }
  }

  func execution(context: OperationMonitor.Context, didError error: Error) {
    errors.append(error)
    switch context {
    case .function(_):
      break
    case .batch, .batchResponse:
      // Indicates a send failure, so don't record counts.
      eventCount = 0
      bytesToSend = 0
      // Flush right away because in the batch case, we won't
      // receive a batchResponse end event. If we get both an
      // error and an end event, the end event's flush will be
      // a no-op.
      flush()
    }
  }

  func execution(context: OperationMonitor.Context,
                 willLog loggingActivity: OperationMonitor.LoggingActivity) {
    switch context {
    case .function(_):
      eventCount += 1
    case .batch:
      if case .data(let data) = loggingActivity {
        bytesToSend += UInt64(data.count)
      }
    case .batchResponse:
      break
    }
  }
}

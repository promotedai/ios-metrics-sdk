import Foundation
import SwiftProtobuf

// MARK: - AnalyticsConnection
/** Wraps an Analytics package. */
public protocol AnalyticsConnection: AnyObject {

  /// Starts analytics services.
  /// Will be called at `startLoggingServices()` time.
  func startServices() throws

  /// Logs a count of events successfully logged.
  func log(eventCount: Int)

  /// Logs a count of bytes successfully sent.
  func log(bytesSent: UInt64)

  /// Logs errors that occurred during logging.
  func log(errors: [Error])
}

protocol AnalyticsConnectionSource {
  var analyticsConnection: AnalyticsConnection? { get }
}

// MARK: - Analytics
final class Analytics {
  private let connection: AnalyticsConnection
  private var eventCount: Int
  private var bytesSent: UInt64
  private var errors: [Error]

  typealias Deps = AnalyticsConnectionSource & OperationMonitorSource

  init(deps: Deps) {
    self.connection = deps.analyticsConnection!
    self.eventCount = 0
    self.bytesSent = 0
    self.errors = []
    deps.operationMonitor.addOperationMonitorListener(self)
  }

  private func flush() {
    if eventCount > 0 {
      connection.log(eventCount: eventCount)
      eventCount = 0
    }
    if bytesSent > 0 {
      connection.log(bytesSent: bytesSent)
      bytesSent = 0
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

  func execution(context: Context, didError error: Error) {
    errors.append(error)
    switch context {
    case .function(_):
      break
    case .batch, .batchResponse:
      // Indicates a send failure, so don't record counts.
      eventCount = 0
      bytesSent = 0
      // Flush right away because in the batch case, we won't
      // receive an executionDidLog event.
      flush()
    }
  }

  func execution(context: Context, willLogMessage message: Message) {
    if case .function(_) = context {
      eventCount += 1
    }
  }

  func execution(context: Context, willLogData data: Data) {
    if case .batch = context {
      bytesSent += UInt64(data.count)
    }
  }

  func executionDidLog(context: Context) {
    flush()
  }
}

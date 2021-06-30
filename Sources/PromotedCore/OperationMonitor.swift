import Foundation
import SwiftProtobuf

// MARK: -
/** Listens for execution scopes. */
protocol OperationMonitorListener: AnyObject {
  typealias Context = OperationMonitor.Context

  /// Called when the outermost `execute()` starts.
  func executionWillStart(context: Context)

  /// Called when the outermost `execute()` ends.
  func executionDidEnd(context: Context)

  /// Called when an error is reported.
  func execution(context: Context, didError error: Error)

  /// Called when a log message will be sent.
  /// In the function context, the message should be an event.
  /// In the batch context, the message should be the LogRequest.
  func execution(context: Context, willLogMessage message: Message)

  /// Called when data will be sent over connection.
  func execution(context: Context, willLogData data: Data)

  /// Called when a log message has been sent successfully.
  /// Context here will always be batchResponse.
  func executionDidLog(context: Context)
}

extension OperationMonitorListener {
  func executionWillStart(context: Context) {}

  func executionDidEnd(context: Context) {}

  func execution(context: Context, didError error: Error) {}

  func execution(context: Context, willLogMessage message: Message) {}

  func execution(context: Context, willLogData data: Data) {}

  func executionDidLog(context: Context) {}
}

// MARK: -
/**
 Wraps all public, client-facing operations. Provides context and
 monitoring for these operations. This includes setting up logging
 state for a series of grouped logging operations, performance
 monitoring, and respecting state of kill switch.
 */
final class OperationMonitor {

  enum Context {
    case function(_ function: String)
    case batch
    case batchResponse
  }

  typealias Operation = () -> Void
  fileprivate typealias Stack = [Context]

  private var listeners: WeakArray<OperationMonitorListener>
  private var contextStack: Stack

  init() {
    self.listeners = []
    self.contextStack = []
  }
  
  func addOperationMonitorListener(_ listener: OperationMonitorListener) {
    listeners.append(listener)
  }
  
  func removeOperationMonitorListener(_ listener: OperationMonitorListener) {
    listeners.removeAll(identicalTo: listener)
  }

  /// Groups a series of operations with the same view, session,
  /// and user context. Avoids doing multiple checks for this
  /// context when logging a large number of events. All public
  /// operations in the Promoted logging API should go through
  /// this mechanism.
  ///
  /// Does check to ensure that logging is enabled before executing.
  /// As such, blocks sent to this may not be executed if the kill
  /// switch is enabled mid-session. Also generates Xray profiling
  /// data for the provided block, if needed.
  ///
  /// Calls to `execute` can be nested, in which case only the
  /// outermost call triggers calls to listeners.
  ///
  /// - Parameters:
  ///   - context: Identifier for execution context for Xray
  ///   - function: Function from which call was made
  ///   - operation: Block to execute if logging enabled
  func execute(context: Context = .function(""),
               function: String = #function,
               operation: Operation) {
    var executionContext = context
    // Fill in function here because the #function macro doesn't
    // work from inside the enum.
    if case .function(_) = context {
      executionContext = .function(function)
    }
    if contextStack.isEmpty {
      listeners.forEach { $0.executionWillStart(context: executionContext) }
    }
    contextStack.push(executionContext)
    defer {
      contextStack.pop()
      if contextStack.isEmpty {
        listeners.forEach { $0.executionDidEnd(context: executionContext) }
      }
    }
    operation()
  }

  /// Call when library operation produces an error.
  func executionDidError(_ error: Error) {
    guard let context = contextStack.bottom else { return }
    listeners.forEach { $0.execution(context: context, didError: error) }
  }

  /// Call when library operation logs a message.
  /// In the function context, the message should be an event.
  /// In the batch context, the message should be the LogRequest.
  func executionWillLog(message: Message) {
    guard let context = contextStack.bottom else { return }
    listeners.forEach {
      $0.execution(context: context, willLogMessage: message)
    }
  }

  /// Call when batch will send a serialized proto.
  func executionWillLog(data: Data) {
    guard let context = contextStack.bottom else { return }
    listeners.forEach { $0.execution(context: context, willLogData: data) }
  }

  /// Call when batch operation has logged a message successfully.
  func executionDidLog() {
    guard let context = contextStack.bottom else { return }
    listeners.forEach { $0.executionDidLog(context: context) }
  }
}

protocol OperationMonitorSource: NoDeps {
  var operationMonitor: OperationMonitor { get }
}

// MARK: -
fileprivate extension OperationMonitor.Stack {

  var top: OperationMonitor.Context? { last }
  var bottom: OperationMonitor.Context? { first }

  mutating func push(_ context: OperationMonitor.Context) {
    append(context)
  }

  @discardableResult mutating func pop() -> OperationMonitor.Context {
    return removeLast()
  }
}

// MARK: -
extension OperationMonitor.Context: CustomDebugStringConvertible {
  public var debugDescription: String {
    switch self {
    case .function(let function):
      return function
    default:
      return String(describing: self)
    }
  }
}

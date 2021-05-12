import Foundation
import SwiftProtobuf

/** Listens for execution scopes. */
protocol OperationMonitorListener: AnyObject {
  /// Called when the outermost `execute()` starts.
  func executionWillStart(context: OperationMonitor.Context)

  /// Called when the outermost `execute()` ends.
  func executionDidEnd(context: OperationMonitor.Context)

  /// Called when an error is reported.
  func execution(context: OperationMonitor.Context, didError error: Error)

  /// Called when a log message is sent.
  func execution(context: OperationMonitor.Context,
                 didLog loggingActivity: OperationMonitor.LoggingActivity)
}

extension OperationMonitorListener {
  func executionWillStart(context: OperationMonitor.Context) {}

  func executionDidEnd(context: OperationMonitor.Context) {}

  func execution(context: OperationMonitor.Context, didError error: Error) {}

  func execution(context: OperationMonitor.Context,
                 didLog loggingActivity: OperationMonitor.LoggingActivity) {}
}


/**
 Wraps all public, client-facing operations. Provides context and
 monitoring for these operations. This includes setting up logging
 state for a series of grouped logging operations, performance
 monitoring, and respecting state of kill switch.
 */
public final class OperationMonitor {

  public enum Context {
    case clientInitiated(function: String)
    case batch
    case batchResponse
  }
  fileprivate typealias Stack = [Context]

  public enum LoggingActivity {
    case protobuf(message: Message)
    case bytes(data: Data)
  }

  public typealias Operation = () -> Void

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
  func execute(context: Context = .clientInitiated(function: ""),
               function: String = #function,
               operation: Operation) {
    var executionContext = context
    // Fill in function here because the #function macro doesn't
    // work from inside the enum call.
    if case .clientInitiated(_) = context {
      executionContext = .clientInitiated(function: function)
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
  public func executionDidError(_ error: Error) {
    guard let context = contextStack.bottom else { return }
    listeners.forEach { $0.execution(context: context, didError: error) }
  }

  /// Call when library operation logs a message.
  public func executionDidLog(_ loggingActivity: LoggingActivity) {
    guard let context = contextStack.bottom else { return }
    listeners.forEach { $0.execution(context: context, didLog: loggingActivity) }
  }
}

protocol OperationMonitorSource {
  var operationMonitor: OperationMonitor { get }
}

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

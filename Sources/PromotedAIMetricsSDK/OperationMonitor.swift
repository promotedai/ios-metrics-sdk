import Foundation

/** Listens for execution scopes. */
protocol OperationMonitorListener: AnyObject {
  /// Called when the outermost `execute()` starts.
  func executionWillStart(context: String)

  /// Called when the outermost `execute()` ends.
  func executionDidEnd(context: String)
}

/**
 Wraps all public, client-facing operations. Provides context and
 monitoring for these operations. This includes setting up logging
 state for a series of grouped logging operations, performance
 monitoring, and respecting state of kill switch.
 */
final class OperationMonitor {

  typealias Operation = () -> Void

  private var listeners: WeakArray<OperationMonitorListener>
  private var exectionDepth: Int
  
  init() {
    self.listeners = []
    self.exectionDepth = 0
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
  ///   - operation: Block to execute if logging enabled
  func execute(context: String = #function, operation: Operation) {
    if exectionDepth == 0 {
      listeners.forEach { $0.executionWillStart(context: context) }
    }
    exectionDepth += 1
    defer {
      exectionDepth -= 1
      if exectionDepth == 0 {
        listeners.forEach { $0.executionDidEnd(context: context) }
      }
    }
    operation()
  }
}

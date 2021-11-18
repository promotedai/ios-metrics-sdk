import Foundation
import os.log

/**
 Sink for errors not handled anywhere else in the SDK.
 Used for async operations that may produce errors
 without a clear error handling scope.
 Avoid using this as a generic error-handling mechanism.
 Prefer to scope errors as closely as possible.
 */
final class ErrorHandler {

  private let osLog: OSLog?

  typealias Deps = (
    OperationMonitorSource &
    OSLogSource
  )

  init(deps: Deps) {
    self.osLog = deps.osLog(category: "ErrorHandler")
    deps.operationMonitor.addOperationMonitorListener(self)
  }
}

protocol ErrorHandlerSource {
  var errorHandler: ErrorHandler? { get }
}

extension ErrorHandler: OperationMonitorListener {
  func execution(context: Context, didError error: Error) {
    osLog?.error("%{private}@", error.localizedDescription)
  }
}

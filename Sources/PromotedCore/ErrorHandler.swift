import Foundation
import os.log

final class ErrorHandler {
  private let osLog: OSLog!

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
    osLog.error("%{private}@", error.localizedDescription)
  }
}

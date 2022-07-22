import Foundation

@testable import PromotedCore

class TestOperationMonitorListener: OperationMonitorListener {
  var starts: [String] = []
  var ends: [String] = []
  var errors: [(String, Error)] = []
  var data: [(String, Data)] = []

  func executionWillStart(context: Context) {
    starts.append(context.debugDescription)
  }

  func executionDidEnd(context: Context) {
    ends.append(context.debugDescription)
  }

  func execution(
    context: Context,
    didError error: Error,
    function: String,
    file: String
  ) {
    errors.append((context.debugDescription, error))
  }

  func execution(context: Context, willLogData data: Data) {
    self.data.append((context.debugDescription, data))
  }
}

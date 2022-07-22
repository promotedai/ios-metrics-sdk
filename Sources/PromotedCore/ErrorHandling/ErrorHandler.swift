import Foundation
import SwiftProtobuf
import os.log

/**
 Analyzes messages for anomalies and triggers responses according to setting
 in `ClientConfig.metricsLoggingErrorHandling`.
 */
class ErrorHandler: OperationMonitorListener {

  typealias Deps = (
    ClientConfigSource &
    OperationMonitorSource &
    OSLogSource &
    UIStateSource
  )

  private let config: ClientConfig
  private let osLog: OSLog?
  private let uiState: UIState

  private var shouldShowModal: Bool

  init(deps: Deps) {
    assert(deps.clientConfig.metricsLoggingErrorHandling > .none)
    config = deps.clientConfig
    osLog = deps.osLog(category: "ErrorHandler")
    uiState = deps.uiState
    shouldShowModal = true
    deps.operationMonitor.addOperationMonitorListener(self)
  }

  func execution(
    context: Context,
    didError error: Error,
    function: String,
    file: String
  ) {
    log(error: error, function: function, file: file)
    switch config.metricsLoggingErrorHandling {
    case .none:
      break
    case .modalDialog:
      #if DEBUG
      if shouldShowModal {
        DispatchQueue.main.async { [weak self] in
          guard let self = self else { return }
          ErrorModalViewController.present(
            partner: self.config.partnerName,
            contactInfo: self.config.promotedContactInfo,
            error: error,
            keyWindow: self.uiState.keyWindow,
            delegate: self
          )
        }
      }
      #endif
    case .breakInDebugger:
      #if DEBUG
      raise(SIGINT)
      #endif
    }
  }

  private func log(error: Error, function: String, file: String) {
    guard let osLog = osLog else { return }
    let basename = URL(fileURLWithPath: file)
      .lastPathComponent
      .replacingOccurrences(of: ".swift", with: "")
    osLog.error(
      "[%{public}@ %{public}@]: %{public}@",
      basename,
      function,
      error.localizedDescription
    )
  }
}

protocol ErrorHandlerSource {
  var errorHandler: ErrorHandler? { get }
}

#if DEBUG
extension ErrorHandler: ErrorModalViewControllerDelegate {
  func errorModalVCDidDismiss(
    _ vc: ErrorModalViewController,
    shouldShowAgain: Bool
  ) {
    shouldShowModal = shouldShowAgain
  }
}
#endif

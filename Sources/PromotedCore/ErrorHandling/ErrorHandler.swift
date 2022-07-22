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
    UIStateSource
  )

  private let config: ClientConfig
  private unowned let uiState: UIState

  private var shouldShowModal: Bool

  init(deps: Deps) {
    assert(deps.clientConfig.metricsLoggingErrorHandling > .none)
    config = deps.clientConfig
    uiState = deps.uiState
    shouldShowModal = true
    deps.operationMonitor.addOperationMonitorListener(self)
  }

  func execution(context: Context, didError error: Error) {
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

import Foundation
import SwiftProtobuf
import os.log

/** Notified when `AnomalyHandler` detects a logging anomaly. */
protocol AnomalyHandlerDelegate: AnyObject {
  func anomalyHandler(
    _ handler: AnomalyHandler,
    didHandleAnomalyType type: AnomalyType,
    message: Message?
  )
}

/**
 Analyzes messages for anomalies and triggers responses according to setting
 in `ClientConfig.loggingAnomalyHandling`.
 */
class AnomalyHandler: OperationMonitorListener {

  typealias Deps = (
    ClientConfigSource &
    OperationMonitorSource &
    OSLogSource &
    UIStateSource
  )

  weak var delegate: AnomalyHandlerDelegate?

  private let config: ClientConfig
  private unowned let osLog: OSLog?
  private unowned let uiState: UIState

  private(set) var anomalyCount: Int
  private var shouldShowModal: Bool

  init(deps: Deps) {
    assert(deps.clientConfig.loggingAnomalyHandling > .none)
    config = deps.clientConfig
    osLog = deps.osLog(category: "AnomalyHandler")
    uiState = deps.uiState
    delegate = nil
    anomalyCount = 0
    shouldShowModal = true
    deps.operationMonitor.addOperationMonitorListener(self)
  }

  func execution(context: Context, didError error: Error) {
    switch error {
    case MetricsLoggerError.missingUserIDsInUserMessage:
      // If an attempt to log a User event without userID AND
      // logUserID occurs, it goes through this path. Otherwise,
      // if it's only missing logUserID, it goes through
      // execution(context:willLogMessage:).
      triggerAnomalyHandlerResponse(
        type: .missingLogUserIDInUserMessage,
        message: nil
      )
    default:
      break
    }
  }

  func execution(context: Context, willLogMessage message: Message) {
    switch message {
    case let logRequest as Event_LogRequest:
      analyze(logRequest: logRequest)
    case let impression as Event_Impression:
      analyze(impression: impression)
    case let action as Event_Action:
      analyze(action: action)
    case let user as Event_User:
      // If an attempt to log a User event without a logUserID
      // occurs (but it has a userID), it goes through this path.
      // Otherwise, it goes through execution(context:didError:).
      analyze(user: user)
    default:
      break
    }
  }

  func analyze(logRequest: Event_LogRequest) {
    if logRequest.userInfo.logUserID.isEmptyOrWhitespace {
      triggerAnomalyHandlerResponse(
        type: .missingLogUserIDInLogRequest,
        message: logRequest
      )
    }
  }

  func analyze(impression: Event_Impression) {
    if (
      impression.sourceType == .delivery &&
      impression.insertionID.isEmptyOrWhitespace &&
      impression.contentID.isEmptyOrWhitespace
    ) {
      triggerAnomalyHandlerResponse(
        type: .missingJoinableFieldsInImpression,
        message: impression
      )
    }
  }

  func analyze(action: Event_Action) {
    if (
      action.actionType != .checkout &&
      action.actionType != .purchase &&
      action.impressionID.isEmptyOrWhitespace &&
      action.insertionID.isEmptyOrWhitespace &&
      action.contentID.isEmptyOrWhitespace
    ) {
      triggerAnomalyHandlerResponse(
        type: .missingJoinableFieldsInAction,
        message: action
      )
    }
  }

  func analyze(user: Event_User) {
    if user.userInfo.logUserID.isEmpty {
      triggerAnomalyHandlerResponse(
        type: .missingLogUserIDInUserMessage,
        message: user
      )
    }
  }

  private func triggerAnomalyHandlerResponse(
    type: AnomalyType,
    message: Message?
  ) {
    anomalyCount += 1
    delegate?.anomalyHandler(
      self,
      didHandleAnomalyType: type,
      message: message
    )
    switch config.loggingAnomalyHandling {
    case .none:
      break
    case .consoleLog:
      osLog?.error(
        "Promoted.ai Metrics Logging Error. (Code=%{public}d, Description=%{public}@",
        type.rawValue,
        type.debugDescription
      )
    case .modalDialog:
      if shouldShowModal {
        DispatchQueue.main.async { [weak self] in
          guard let self = self else { return }
          AnomalyModalViewController.present(
            partner: self.config.partnerName,
            contactInfo: self.config.promotedContactInfo,
            anomalyType: type,
            keyWindow: self.uiState.keyWindow,
            delegate: self
          )
        }
      }
    case .breakInDebugger:
      #if DEBUG
      raise(SIGINT)
      #endif
    }
  }
}

protocol AnomalyHandlerSource {
  var anomalyHandler: AnomalyHandler? { get }
}

extension AnomalyHandler: AnomalyModalViewControllerDelegate {
  func  anomalyModalVCDidDismiss(
    _ vc: AnomalyModalViewController,
    shouldShowAgain: Bool
  ) {
    shouldShowModal = shouldShowAgain
  }
}

fileprivate extension String {
  var isEmptyOrWhitespace: Bool {
    return isEmpty || trimmingCharacters(in: .whitespaces).isEmpty
  }
}

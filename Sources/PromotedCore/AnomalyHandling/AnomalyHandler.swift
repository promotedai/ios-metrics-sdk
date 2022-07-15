import Foundation
import SwiftProtobuf
import os.log

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
    anomalyCount = 0
    shouldShowModal = true
    deps.operationMonitor.addOperationMonitorListener(self)
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
      analyze(user: user)
    default:
      break
    }
  }

  func analyze(logRequest: Event_LogRequest) {
    if logRequest.userInfo.logUserID.isEmptyOrWhitespace {
      triggerAnomalyHandlerResponse(type: .missingLogUserIDInLogRequest)
    }
  }

  func analyze(impression: Event_Impression) {
    if (
      impression.sourceType == .delivery &&
      impression.insertionID.isEmptyOrWhitespace &&
      impression.contentID.isEmptyOrWhitespace
    ) {
      triggerAnomalyHandlerResponse(type: .missingJoinableFieldsInImpression)
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
      triggerAnomalyHandlerResponse(type: .missingJoinableFieldsInAction)
    }
  }

  func analyze(user: Event_User) {
    if user.userInfo.logUserID.isEmpty {
      triggerAnomalyHandlerResponse(type: .missingLogUserIDInUserMessage)
    }
  }

  private func triggerAnomalyHandlerResponse(type: AnomalyType) {
    anomalyCount += 1
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
          self?.showAnomalyModal(type: type)
        }
      }
    case .breakInDebugger:
      #if DEBUG
      raise(SIGINT)
      #endif
    }
  }

  private func showAnomalyModal(type: AnomalyType) {
    guard
      let rootVC = uiState.keyWindow?.rootViewController,
      rootVC.presentedViewController == nil
    else { return }
    let vc = AnomalyModalViewController(
      partner: config.partnerName,
      contactInfo: config.promotedContactInfo,
      anomalyType: type,
      delegate: self
    )
    rootVC.present(vc, animated: true)
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

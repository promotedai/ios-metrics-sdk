import Foundation
import SwiftProtobuf

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

  private var shouldShowModal: Bool

  init(deps: Deps) {
    config = deps.clientConfig
    osLog = deps.osLog(category: "AnomalyHandler")
    shouldShowModal = true
    uiState = deps.uiState
    super.init()
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
    switch config.loggingAnomalyHandling {
    case .none:
      break
    case .consoleLog:
      osLog?.error(
        "Promoted.ai Metrics Logging Error. " +
        "(Code=\(type.rawValue), Description=\(type.debugDescription)"
      )
    case .modalDialog:
      if shouldShowModal {
        if let rootVC = uiState.keyWindow?.rootViewController {
          let vc = AnomalyModalViewController(
            partner: config.partnerName,
            contactInfo: config.promotedContactInfo,
            anomalyType: type
          )
          rootVC.present(vc, animated: true)
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

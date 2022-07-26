import Foundation
import SwiftProtobuf

extension MetricsLogger {
  func validate(message: Message) {
    switch message {
    case let logRequest as Event_LogRequest:
      validate(logRequest: logRequest)
    case let impression as Event_Impression:
      validate(impression: impression)
    case let action as Event_Action:
      validate(action: action)
    case let user as Event_User:
      validate(user: user)
    default:
      break
    }
  }

  private func validate(logRequest: Event_LogRequest) {
    if logRequest.userInfo.logUserID.isEmptyOrWhitespace {
      handleLoggingError(.missingLogUserIDInLogRequest)
    }
  }

  private func validate(impression: Event_Impression) {
    if (
      impression.sourceType == .delivery &&
      impression.insertionID.isEmptyOrWhitespace &&
      impression.contentID.isEmptyOrWhitespace
    ) {
      handleLoggingError(.missingJoinableIDsInImpression)
    }
  }

  private func validate(action: Event_Action) {
    if (
      action.actionType != .checkout &&
      action.actionType != .purchase &&
      action.impressionID.isEmptyOrWhitespace &&
      action.insertionID.isEmptyOrWhitespace &&
      action.contentID.isEmptyOrWhitespace
    ) {
      handleLoggingError(.missingJoinableIDsInAction)
    }
  }

  private func validate(user: Event_User) {
    if (
      user.userInfo.logUserID.isEmptyOrWhitespace &&
      user.userInfo.userID.isEmptyOrWhitespace
    ) {
      handleLoggingError(.missingLogUserIDInUserMessage)
    }
  }
}

fileprivate extension String {
  var isEmptyOrWhitespace: Bool {
    return isEmpty || trimmingCharacters(in: .whitespaces).isEmpty
  }
}

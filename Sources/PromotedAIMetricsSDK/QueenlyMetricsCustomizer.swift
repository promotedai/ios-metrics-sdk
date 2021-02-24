import Foundation
import Protobuf
import SchemaObjC

@objc(PADefaultMetricsCustomizer)
public class QueenlyMetricsCustomizer: NSObject, MetricsCustomizer {
  public func sessionStartMessage(commonMessage: PSESession) -> GPBMessage {
    var session = PSQQueenlySession()
    session.common = commonMessage
    return session
  }
  
  public func userMessage(commonMessage: PSEUser) -> GPBMessage {
    var user = PSQQueenlyUser()
    user.common = commonMessage
    return user
  }
  
  public func sessionProfileMessage(commonMessage: PSESessionProfile) -> GPBMessage {
    var sessionProfile = PSQQueenlySessionProfile()
    sessionProfile.common = commonMessage
    return sessionProfile
  }
  
  public func sessionMessage(commonMessage: PSESession) -> GPBMessage {
    var session = PSQQueenlySession()
    session.common = commonMessage
    return session
  }
  
  public func viewMessage(commonMessage: PSEView) -> GPBMessage {
    var view = PSQQueenlyView()
    view.common = commonMessage
    return view
  }
  
  public func requestMessage(commonMessage: PSERequest) -> GPBMessage {
    var request = PSQQueenlyRequest()
    request.common = commonMessage
    return request
  }
  
  public func insertionMessage(commonMessage: PSEInsertion) -> GPBMessage {
    var insertion = PSQQueenlyInsertion()
    insertion.common = commonMessage
    return insertion
  }

  public func impressionMessage(commonMessage: PSEImpression) -> GPBMessage {
    var impression = PSQQueenlyImpression()
    impression.common = commonMessage
    return commonMessage
  }
  
  public func clickMessage(commonMessage: PSEClick) -> GPBMessage {
    var click = PSQQueenlyClick()
    click.common = commonMessage
    return click
  }
  
  public func batchLogMessage(contents: [GPBMessage]) -> GPBMessage {
    var batchMessage = PSQQueenlyBatchLogRequest()
    for message in contents {
      switch message {
      case let user as PSQQueenlyUser:
        batchMessage.userArray.add(user)
      case let sessionProfile as PSQQueenlySessionProfile:
        batchMessage.sessionProfileArray.add(sessionProfile)
      case let session as PSQQueenlySession:
        batchMessage.sessionArray.add(session)
      case let view as PSQQueenlyView:
        batchMessage.viewArray.add(view)
      case let request as PSQQueenlyRequest:
        batchMessage.requestArray.add(request)
      case let insertion as PSQQueenlyInsertion:
        batchMessage.insertionArray.add(insertion)
      case let impression as PSQQueenlyImpression:
        batchMessage.impressionArray.add(impression)
      case let click as PSQQueenlyClick:
        batchMessage.clickArray.add(click)
      default:
        print("Unknown message: \(message)")
      }
    }
    return batchMessage
  }
}

import Foundation
import Protobuf

#if canImport(SchemaProtosObjC)
import SchemaProtosObjC
#endif


@objc(PAQueenlyMetricsCustomizer)
public class QueenlyMetricsCustomizer: NSObject, ObjCMetricsCustomizer {
  @objc public func sessionStartMessage(commonMessage: PSESession, clientMessage: GPBMessage?) -> GPBMessage {
    var session = clientMessage as? PSQQueenlySession ?? PSQQueenlySession()
    ProtobufSilenceVarWarning(&session)
    session.common = commonMessage
    return session
  }
//
//  public func userMessage(commonMessage: PSEUser) -> GPBMessage {
//    var user = PSQQueenlyUser()
//    user.common = commonMessage
//    return user
//  }
//
//  public func sessionProfileMessage(commonMessage: PSESessionProfile) -> GPBMessage {
//    var sessionProfile = PSQQueenlySessionProfile()
//    sessionProfile.common = commonMessage
//    return sessionProfile
//  }
//
//  public func sessionMessage(commonMessage: PSESession) -> GPBMessage {
//    var session = PSQQueenlySession()
//    session.common = commonMessage
//    return session
//  }
//
//  public func viewMessage(commonMessage: PSEView) -> GPBMessage {
//    var view = PSQQueenlyView()
//    view.common = commonMessage
//    return view
//  }
//
//  public func requestMessage(commonMessage: PSERequest) -> GPBMessage {
//    var request = PSQQueenlyRequest()
//    request.common = commonMessage
//    return request
//  }
//
//  public func insertionMessage(commonMessage: PSEInsertion) -> GPBMessage {
//    var insertion = PSQQueenlyInsertion()
//    insertion.common = commonMessage
//    return insertion
//  }

  @objc public func impressionMessage(commonMessage: PSEImpression, clientMessage: GPBMessage?) -> GPBMessage {
    var impression = clientMessage as? PSQQueenlyImpression ?? PSQQueenlyImpression()
    ProtobufSilenceVarWarning(&impression)
    impression.common = commonMessage
    return commonMessage
  }
  
  @objc public func clickMessage(commonMessage: PSEClick, clientMessage: GPBMessage?) -> GPBMessage {
    var click = clientMessage as? PSQQueenlyClick ?? PSQQueenlyClick()
    ProtobufSilenceVarWarning(&click)
    click.common = commonMessage
    return click
  }
  
  @objc public func batchLogMessage(contents: [GPBMessage]) -> GPBMessage {
    var batchMessage = PSQQueenlyBatchLogRequest()
    ProtobufSilenceVarWarning(&batchMessage)
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

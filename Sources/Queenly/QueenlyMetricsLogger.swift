import Foundation
import Protobuf
import SchemaProtosObjC

@objc(QueenlyMetricsLogger)
public class QueenlyMetricsLogger: MetricsLogger {

  @objc public func logSessionStart(clientData: ClientData? = nil) {
    var session = PSQQueenlySession()
    ProtobufSilenceVarWarning(&session)
    session.common = commonSessionStartEvent()
    log(session)
  }

  @objc public func logImpression(clientData: ClientData? = nil) {
    var impression = PSQQueenlyImpression()
    ProtobufSilenceVarWarning(&impression)
    impression.common = commonImpressionEvent()
    log(commonMessage)
  }
  
  @objc public func logClick(clientData: ClientData? = nil) {
    var click = PSQQueenlyClick()
    ProtobufSilenceVarWarning(&click)
    click.common = commonClickEvent
    log(click)
  }

  override public func batchLogMessage(events: [LogMessage]) -> LogMessage? {
    var batchMessage = PSQQueenlyBatchLogRequest()
    ProtobufSilenceVarWarning(&batchMessage)
    for event in events {
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

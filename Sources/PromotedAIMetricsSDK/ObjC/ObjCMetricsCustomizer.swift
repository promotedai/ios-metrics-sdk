import Foundation
import Protobuf

#if canImport(SchemaProtosObjC)
import SchemaProtosObjC
#endif

@objc(PAMetricsCustomizer)
public protocol ObjCMetricsCustomizer {
  func sessionStartMessage(commonMessage: PSESession, clientMessage: GPBMessage?) -> GPBMessage

//  func userMessage(commonMessage: PSEUser) -> GPBMessage
//  func sessionProfileMessage(commonMessage: PSESessionProfile) -> GPBMessage
//  func sessionMessage(commonMessage: PSESession) -> GPBMessage
//  func viewMessage(commonMessage: PSEView) -> GPBMessage
//  func requestMessage(commonMessage: PSERequest) -> GPBMessage
//  func insertionMessage(commonMessage: PSEInsertion) -> GPBMessage
  func impressionMessage(commonMessage: PSEImpression, clientMessage: GPBMessage?) -> GPBMessage
  func clickMessage(commonMessage: PSEClick, clientMessage: GPBMessage?) -> GPBMessage
  
  func batchLogMessage(contents: [GPBMessage]) -> GPBMessage
}

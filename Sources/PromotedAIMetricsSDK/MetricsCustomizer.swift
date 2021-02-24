import Foundation
import Protobuf
import SchemaObjC

@objc(PAMetricsCustomizer)
public protocol MetricsCustomizer {
  func sessionStartMessage(commonMessage: PSESession) -> GPBMessage
  
  func userMessage(commonMessage: PSEUser) -> GPBMessage
  func sessionProfileMessage(commonMessage: PSESessionProfile) -> GPBMessage
  func sessionMessage(commonMessage: PSESession) -> GPBMessage
  func viewMessage(commonMessage: PSEView) -> GPBMessage
  func requestMessage(commonMessage: PSERequest) -> GPBMessage
  func insertionMessage(commonMessage: PSEInsertion) -> GPBMessage
  func impressionMessage(commonMessage: PSEImpression) -> GPBMessage
  func clickMessage(commonMessage: PSEClick) -> GPBMessage
  
  func batchLogMessage(contents: [GPBMessage]) -> GPBMessage
}

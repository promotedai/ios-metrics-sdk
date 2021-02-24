import Foundation
import SwiftProtobuf

#if canImport(SchemaProtosSwift)
import SchemaProtosSwift
#endif

public protocol MetricsCustomizer {
  func sessionStartMessage(commonMessage: Event_Session, clientMessage: Message?) -> Message

//  func userMessage(commonMessage: Event_User) -> GPBMessage
//  func sessionProfileMessage(commonMessage: Event_SessionProfile) -> Message
//  func sessionMessage(commonMessage: Event_Session) -> Message
//  func viewMessage(commonMessage: Event_View) -> Message
//  func requestMessage(commonMessage: Event_Request) -> Message
//  func insertionMessage(commonMessage: Event_Insertion) -> Message
  func impressionMessage(commonMessage: Event_Impression, clientMessage: Message?) -> Message
  func clickMessage(commonMessage: Event_Click, clientMessage: Message?) -> Message
  
  func batchLogMessage(contents: [Message]) -> Message
}

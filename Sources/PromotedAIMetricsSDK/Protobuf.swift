import Foundation

#if canImport(Protobuf)

import Protobuf

public typealias LogMessage = GPBMessage
public typealias SessionEvent = PSESession
public typealias ImpressionEvent = PSEImpression
public typealias ClickEvent = PSEClick

extension PSESession {
  var platformID: UInt64 {
    get { return self.platformId }
    set(value) { self.platformId = value }
  }
  var logUserID: String {
    get { return self.logUserId }
    set(value) { self.logUserId = value }
  }
  var sessionID: String {
    get { return self.sessionId }
    set(value) { self.sessionId = value }
  }
}

extension PSEImpression {
  var sessionID: String {
    get { return self.sessionId }
    set(value) { self.sessionId = value }
  }
}

extension PSEClick {
  var sessionID: String {
    get { return self.sessionId }
    set(value) { self.sessionId = value }
  }
}

extension GPBMessage {
  func serializedData() throws -> Data  {
    guard let result = self.data() else { throw MessageSerializationError.unknownError }
    return result
  }
}

#elseif canImport(SwiftProtobuf)

import SwiftProtobuf
import SchemaProtosSwift

public typealias LogMessage = Message
public typealias SessionEvent = Event_Session
public typealias ImpressionEvent = Event_Impression
public typealias ClickEvent = Event_Click

#endif

func ProtobufSilenceVarWarning<P>(_ a: inout P) {}

enum MessageSerializationError: Error {
  case unknownError
}

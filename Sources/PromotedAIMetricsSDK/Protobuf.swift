import Foundation

public class Protobuf {
  public static func SilenceVarWarning<P>(_ a: inout P) {}
}

enum MessageSerializationError: Error {
  case unknownError
}

#if canImport(Protobuf)

import Protobuf

public typealias LogMessage = GPBMessage

public typealias UserEvent = PROUser
extension PROUser {
  var platformID: UInt64 {
    get { return self.platformId }
    set(value) { self.platformId = value }
  }
  var userID: String? {
    get { return self.userId }
    set(value) { self.userId = value }
  }
  var logUserID: String? {
    get { return self.logUserId }
    set(value) { self.logUserId = value }
  }
}

public typealias ImpressionEvent = PROImpression
extension PROImpression {
  var platformID: UInt64 {
    get { return self.platformId }
    set(value) { self.platformId = value }
  }
  var logUserID: String? {
    get { return self.logUserId }
    set(value) { self.logUserId = value }
  }
  var impressionID: String? {
    get { return self.impressionId }
    set(value) { self.impressionId = value }
  }
  var insertionID: String? {
    get { return self.insertionId }
    set(value) { self.insertionId = value }
  }
  var requestID: String? {
    get { return self.requestId }
    set(value) { self.requestId = value }
  }
  var sessionID: String? {
    get { return self.sessionId }
    set(value) { self.sessionId = value }
  }
  var viewID: String? {
    get { return self.viewId }
    set(value) { self.viewId = value }
  }
}

public typealias ClickEvent = PROClick
extension PROClick {
  var platformID: UInt64 {
    get { return self.platformId }
    set(value) { self.platformId = value }
  }
  var logUserID: String? {
    get { return self.logUserId }
    set(value) { self.logUserId = value }
  }
  var clickID: String? {
    get { return self.clickId }
    set(value) { self.clickId = value }
  }
  var impressionID: String? {
    get { return self.impressionId }
    set(value) { self.impressionId = value }
  }
  var insertionID: String? {
    get { return self.insertionId }
    set(value) { self.insertionId = value }
  }
  var requestID: String? {
    get { return self.requestId }
    set(value) { self.requestId = value }
  }
  var sessionID: String? {
    get { return self.sessionId }
    set(value) { self.sessionId = value }
  }
  var viewID: String? {
    get { return self.viewId }
    set(value) { self.viewId = value }
  }
  var elementID: String? {
    get { return self.elementId }
    set(value) { self.elementId = value }
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
public typealias UserEvent = Event_User
public typealias ImpressionEvent = Event_Impression
public typealias ClickEvent = Event_Click

#endif

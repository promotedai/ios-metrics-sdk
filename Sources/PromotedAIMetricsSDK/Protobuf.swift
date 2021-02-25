import Foundation

#if canImport(Protobuf)

import Protobuf
import SchemaProtosObjC

public typealias LogMessage = GPBMessage
public typealias SessionEvent = PSESession
public typealias ImpressionEvent = PSEImpression
public typealias ClickEvent = PSEClick

#elseif canImport(SwiftProtobuf)

import SwiftProtobuf
import SchemaProtosSwift

public typealias LogMessage = Message
public typealias SessionEvent = Event_Session
public typealias ImpressionEvent = Event_Impression
public typealias ClickEvent = Event_Click

#endif

func ProtobufSilenceVarWarning<P>(_ a: inout P) {}

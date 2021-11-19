// DO NOT EDIT.
// swift-format-ignore-file
//
// Generated by the Swift generator plugin for the protocol buffer compiler.
// Source: proto/delivery/execution.proto
//
// For information on using the generated types, please see the documentation:
//   https://github.com/apple/swift-protobuf/

import Foundation
import SwiftProtobuf

// If the compiler emits an error on this type, it is because this file
// was generated by a version of the `protoc` Swift plug-in that is
// incompatible with the version of SwiftProtobuf to which you are linking.
// Please ensure that you are building against the same version of the API
// that was used to generate this file.
fileprivate struct _GeneratedWithProtocGenSwiftVersion: SwiftProtobuf.ProtobufAPIVersionCheck {
  struct _2: SwiftProtobuf.ProtobufAPIVersion_2 {}
  typealias Version = _2
}

/// The system repsonsible for doing delivery.
/// Next ID = 4
public enum Delivery_ExecutionServer: SwiftProtobuf.Enum {
  public typealias RawValue = Int
  case unknownExecutionServer // = 0

  /// The SDK did delivery because the API failed or was not called for any reason.
  case sdk // = 2
  case UNRECOGNIZED(Int)

  public init() {
    self = .unknownExecutionServer
  }

  public init?(rawValue: Int) {
    switch rawValue {
    case 0: self = .unknownExecutionServer
    case 2: self = .sdk
    default: self = .UNRECOGNIZED(rawValue)
    }
  }

  public var rawValue: Int {
    switch self {
    case .unknownExecutionServer: return 0
    case .sdk: return 2
    case .UNRECOGNIZED(let i): return i
    }
  }

}

#if swift(>=4.2)

extension Delivery_ExecutionServer: CaseIterable {
  // The compiler won't synthesize support with the UNRECOGNIZED case.
  public static var allCases: [Delivery_ExecutionServer] = [
    .unknownExecutionServer,
    .sdk,
  ]
}

#endif  // swift(>=4.2)

/// Full execution details of a single Delivery hit: Request->Execution->Response.
/// Next ID = 5.
public struct Delivery_DeliveryLog {
  // SwiftProtobuf.Message conformance is added in an extension below. See the
  // `Message` and `Message+*Additions` files in the SwiftProtobuf library for
  // methods supported on all messages.

  /// As used by Delivery. May be set by Delivery per server environment.
  public var platformID: UInt64 = 0

  /// Should be exactly what Delivery API received as input.
  /// request.insertion will be filled in if client does retrieval.
  public var request: Delivery_Request {
    get {return _request ?? Delivery_Request()}
    set {_request = newValue}
  }
  /// Returns true if `request` has been explicitly set.
  public var hasRequest: Bool {return self._request != nil}
  /// Clears the value of `request`. Subsequent reads from it will return its default value.
  public mutating func clearRequest() {self._request = nil}

  /// Should be exactly what Delivery API sent as output.
  /// response.insertion will be filled in with the paged response.
  public var response: Delivery_Response {
    get {return _response ?? Delivery_Response()}
    set {_response = newValue}
  }
  /// Returns true if `response` has been explicitly set.
  public var hasResponse: Bool {return self._response != nil}
  /// Clears the value of `response`. Subsequent reads from it will return its default value.
  public mutating func clearResponse() {self._response = nil}

  public var execution: Delivery_DeliveryExecution {
    get {return _execution ?? Delivery_DeliveryExecution()}
    set {_execution = newValue}
  }
  /// Returns true if `execution` has been explicitly set.
  public var hasExecution: Bool {return self._execution != nil}
  /// Clears the value of `execution`. Subsequent reads from it will return its default value.
  public mutating func clearExecution() {self._execution = nil}

  public var unknownFields = SwiftProtobuf.UnknownStorage()

  public init() {}

  fileprivate var _request: Delivery_Request? = nil
  fileprivate var _response: Delivery_Response? = nil
  fileprivate var _execution: Delivery_DeliveryExecution? = nil
}

/// Contains the inner execution details for a Delivery call.
/// Next ID = 7.
public struct Delivery_DeliveryExecution {
  // SwiftProtobuf.Message conformance is added in an extension below. See the
  // `Message` and `Message+*Additions` files in the SwiftProtobuf library for
  // methods supported on all messages.

  /// Where delivery happened, i.e. via the SDK or some approach on the API side.
  public var executionServer: Delivery_ExecutionServer = .unknownExecutionServer

  public var unknownFields = SwiftProtobuf.UnknownStorage()

  public init() {}
}

// MARK: - Code below here is support for the SwiftProtobuf runtime.

fileprivate let _protobuf_package = "delivery"

extension Delivery_ExecutionServer: SwiftProtobuf._ProtoNameProviding {
  public static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
    0: .same(proto: "UNKNOWN_EXECUTION_SERVER"),
    2: .same(proto: "SDK"),
  ]
}

extension Delivery_DeliveryLog: SwiftProtobuf.Message, SwiftProtobuf._MessageImplementationBase, SwiftProtobuf._ProtoNameProviding {
  public static let protoMessageName: String = _protobuf_package + ".DeliveryLog"
  public static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
    1: .standard(proto: "platform_id"),
    2: .same(proto: "request"),
    3: .same(proto: "response"),
    4: .same(proto: "execution"),
  ]

  public mutating func decodeMessage<D: SwiftProtobuf.Decoder>(decoder: inout D) throws {
    while let fieldNumber = try decoder.nextFieldNumber() {
      // The use of inline closures is to circumvent an issue where the compiler
      // allocates stack space for every case branch when no optimizations are
      // enabled. https://github.com/apple/swift-protobuf/issues/1034
      switch fieldNumber {
      case 1: try { try decoder.decodeSingularUInt64Field(value: &self.platformID) }()
      case 2: try { try decoder.decodeSingularMessageField(value: &self._request) }()
      case 3: try { try decoder.decodeSingularMessageField(value: &self._response) }()
      case 4: try { try decoder.decodeSingularMessageField(value: &self._execution) }()
      default: break
      }
    }
  }

  public func traverse<V: SwiftProtobuf.Visitor>(visitor: inout V) throws {
    if self.platformID != 0 {
      try visitor.visitSingularUInt64Field(value: self.platformID, fieldNumber: 1)
    }
    if let v = self._request {
      try visitor.visitSingularMessageField(value: v, fieldNumber: 2)
    }
    if let v = self._response {
      try visitor.visitSingularMessageField(value: v, fieldNumber: 3)
    }
    if let v = self._execution {
      try visitor.visitSingularMessageField(value: v, fieldNumber: 4)
    }
    try unknownFields.traverse(visitor: &visitor)
  }

  public static func ==(lhs: Delivery_DeliveryLog, rhs: Delivery_DeliveryLog) -> Bool {
    if lhs.platformID != rhs.platformID {return false}
    if lhs._request != rhs._request {return false}
    if lhs._response != rhs._response {return false}
    if lhs._execution != rhs._execution {return false}
    if lhs.unknownFields != rhs.unknownFields {return false}
    return true
  }
}

extension Delivery_DeliveryExecution: SwiftProtobuf.Message, SwiftProtobuf._MessageImplementationBase, SwiftProtobuf._ProtoNameProviding {
  public static let protoMessageName: String = _protobuf_package + ".DeliveryExecution"
  public static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
    2: .standard(proto: "execution_server"),
  ]

  public mutating func decodeMessage<D: SwiftProtobuf.Decoder>(decoder: inout D) throws {
    while let fieldNumber = try decoder.nextFieldNumber() {
      // The use of inline closures is to circumvent an issue where the compiler
      // allocates stack space for every case branch when no optimizations are
      // enabled. https://github.com/apple/swift-protobuf/issues/1034
      switch fieldNumber {
      case 2: try { try decoder.decodeSingularEnumField(value: &self.executionServer) }()
      default: break
      }
    }
  }

  public func traverse<V: SwiftProtobuf.Visitor>(visitor: inout V) throws {
    if self.executionServer != .unknownExecutionServer {
      try visitor.visitSingularEnumField(value: self.executionServer, fieldNumber: 2)
    }
    try unknownFields.traverse(visitor: &visitor)
  }

  public static func ==(lhs: Delivery_DeliveryExecution, rhs: Delivery_DeliveryExecution) -> Bool {
    if lhs.executionServer != rhs.executionServer {return false}
    if lhs.unknownFields != rhs.unknownFields {return false}
    return true
  }
}

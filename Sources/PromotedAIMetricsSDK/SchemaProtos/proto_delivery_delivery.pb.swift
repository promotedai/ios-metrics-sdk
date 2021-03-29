// DO NOT EDIT.
// swift-format-ignore-file
//
// Generated by the Swift generator plugin for the protocol buffer compiler.
// Source: proto/delivery/delivery.proto
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

/// Used to indicate the client's use case.  Used on both View and Request.
///
/// Next ID = 11.
public enum Delivery_UseCase: SwiftProtobuf.Enum {
  public typealias RawValue = Int
  case unknownUseCase // = 0

  /// Need to handle in wrapper proto.
  case custom // = 1
  case search // = 2
  case searchSuggestions // = 3
  case feed // = 4
  case relatedContent // = 5
  case closeUp // = 6
  case categoryContent // = 7
  case myContent // = 8
  case mySavedContent // = 9
  case sellerContent // = 10
  case UNRECOGNIZED(Int)

  public init() {
    self = .unknownUseCase
  }

  public init?(rawValue: Int) {
    switch rawValue {
    case 0: self = .unknownUseCase
    case 1: self = .custom
    case 2: self = .search
    case 3: self = .searchSuggestions
    case 4: self = .feed
    case 5: self = .relatedContent
    case 6: self = .closeUp
    case 7: self = .categoryContent
    case 8: self = .myContent
    case 9: self = .mySavedContent
    case 10: self = .sellerContent
    default: self = .UNRECOGNIZED(rawValue)
    }
  }

  public var rawValue: Int {
    switch self {
    case .unknownUseCase: return 0
    case .custom: return 1
    case .search: return 2
    case .searchSuggestions: return 3
    case .feed: return 4
    case .relatedContent: return 5
    case .closeUp: return 6
    case .categoryContent: return 7
    case .myContent: return 8
    case .mySavedContent: return 9
    case .sellerContent: return 10
    case .UNRECOGNIZED(let i): return i
    }
  }

}

#if swift(>=4.2)

extension Delivery_UseCase: CaseIterable {
  // The compiler won't synthesize support with the UNRECOGNIZED case.
  public static var allCases: [Delivery_UseCase] = [
    .unknownUseCase,
    .custom,
    .search,
    .searchSuggestions,
    .feed,
    .relatedContent,
    .closeUp,
    .categoryContent,
    .myContent,
    .mySavedContent,
    .sellerContent,
  ]
}

#endif  // swift(>=4.2)

/// Next ID = 5.
public enum Delivery_BlenderRuleType: SwiftProtobuf.Enum {
  public typealias RawValue = Int
  case unknownRuleType // = 0
  case positive // = 1
  case insert // = 2
  case negative // = 3
  case diversity // = 4
  case UNRECOGNIZED(Int)

  public init() {
    self = .unknownRuleType
  }

  public init?(rawValue: Int) {
    switch rawValue {
    case 0: self = .unknownRuleType
    case 1: self = .positive
    case 2: self = .insert
    case 3: self = .negative
    case 4: self = .diversity
    default: self = .UNRECOGNIZED(rawValue)
    }
  }

  public var rawValue: Int {
    switch self {
    case .unknownRuleType: return 0
    case .positive: return 1
    case .insert: return 2
    case .negative: return 3
    case .diversity: return 4
    case .UNRECOGNIZED(let i): return i
    }
  }

}

#if swift(>=4.2)

extension Delivery_BlenderRuleType: CaseIterable {
  // The compiler won't synthesize support with the UNRECOGNIZED case.
  public static var allCases: [Delivery_BlenderRuleType] = [
    .unknownRuleType,
    .positive,
    .insert,
    .negative,
    .diversity,
  ]
}

#endif  // swift(>=4.2)

/// Represents a Request for Insertions (Content).
/// Can be used to log existing ranking (not Promoted) or Promoted's Delivery
/// API requests.
///
/// TODO - this message will get restructured when we support streaming RPCs.
///
/// Next ID = 14.
public struct Delivery_Request {
  // SwiftProtobuf.Message conformance is added in an extension below. See the
  // `Message` and `Message+*Additions` files in the SwiftProtobuf library for
  // methods supported on all messages.

  /// Optional.  If not set, set by API servers.
  /// If not set, API server uses LogRequest.platform_id.
  public var platformID: UInt64 = 0

  /// Optional.  Must be set on LogRequest or here.
  public var userInfo: Common_UserInfo {
    get {return _userInfo ?? Common_UserInfo()}
    set {_userInfo = newValue}
  }
  /// Returns true if `userInfo` has been explicitly set.
  public var hasUserInfo: Bool {return self._userInfo != nil}
  /// Clears the value of `userInfo`. Subsequent reads from it will return its default value.
  public mutating func clearUserInfo() {self._userInfo = nil}

  /// Optional.  If not set, set by API servers.
  /// If not set, API server uses LogRequest.timing.
  public var timing: Common_Timing {
    get {return _timing ?? Common_Timing()}
    set {_timing = newValue}
  }
  /// Returns true if `timing` has been explicitly set.
  public var hasTiming: Bool {return self._timing != nil}
  /// Clears the value of `timing`. Subsequent reads from it will return its default value.
  public mutating func clearTiming() {self._timing = nil}

  /// Required.  This is a UUID that is generated by the client.
  public var requestID: String = String()

  /// Required.
  public var viewID: String = String()

  /// Optional.
  public var sessionID: String = String()

  /// Optional.
  public var useCase: Delivery_UseCase = .unknownUseCase

  /// Optional.
  public var searchQuery: String = String()

  /// Optional.
  /// If set in Delivery API, Promoted will re-rank this list of Content.
  /// This list can be used to pass in a list of Content (or Content IDs).
  /// If set in Metrics API, Promoted will separate this list of Insertions
  /// into separate log records.
  public var insertion: [Delivery_Insertion] = []

  /// Optional.
  public var deliveryConfig: Delivery_DeliveryConfig {
    get {return _deliveryConfig ?? Delivery_DeliveryConfig()}
    set {_deliveryConfig = newValue}
  }
  /// Returns true if `deliveryConfig` has been explicitly set.
  public var hasDeliveryConfig: Bool {return self._deliveryConfig != nil}
  /// Clears the value of `deliveryConfig`. Subsequent reads from it will return its default value.
  public mutating func clearDeliveryConfig() {self._deliveryConfig = nil}

  /// Optional.  Custom properties per platform.
  public var properties: Common_Properties {
    get {return _properties ?? Common_Properties()}
    set {_properties = newValue}
  }
  /// Returns true if `properties` has been explicitly set.
  public var hasProperties: Bool {return self._properties != nil}
  /// Clears the value of `properties`. Subsequent reads from it will return its default value.
  public mutating func clearProperties() {self._properties = nil}

  public var unknownFields = SwiftProtobuf.UnknownStorage()

  public init() {}

  fileprivate var _userInfo: Common_UserInfo? = nil
  fileprivate var _timing: Common_Timing? = nil
  fileprivate var _deliveryConfig: Delivery_DeliveryConfig? = nil
  fileprivate var _properties: Common_Properties? = nil
}

/// Next ID = 3.
public struct Delivery_Response {
  // SwiftProtobuf.Message conformance is added in an extension below. See the
  // `Message` and `Message+*Additions` files in the SwiftProtobuf library for
  // methods supported on all messages.

  /// List of content.
  public var insertion: [Delivery_Insertion] = []

  public var unknownFields = SwiftProtobuf.UnknownStorage()

  public init() {}
}

/// Next ID = 4.
public struct Delivery_BlenderRule {
  // SwiftProtobuf.Message conformance is added in an extension below. See the
  // `Message` and `Message+*Additions` files in the SwiftProtobuf library for
  // methods supported on all messages.

  public var ruleType: Delivery_BlenderRuleType = .unknownRuleType

  /// set up priority for each rule to resolve conflicts
  public var priority: UInt32 = 0

  /// strategy related attributes
  public var properties: Common_Properties {
    get {return _properties ?? Common_Properties()}
    set {_properties = newValue}
  }
  /// Returns true if `properties` has been explicitly set.
  public var hasProperties: Bool {return self._properties != nil}
  /// Clears the value of `properties`. Subsequent reads from it will return its default value.
  public mutating func clearProperties() {self._properties = nil}

  public var unknownFields = SwiftProtobuf.UnknownStorage()

  public init() {}

  fileprivate var _properties: Common_Properties? = nil
}

/// Next ID = 2.
public struct Delivery_DeliveryConfig {
  // SwiftProtobuf.Message conformance is added in an extension below. See the
  // `Message` and `Message+*Additions` files in the SwiftProtobuf library for
  // methods supported on all messages.

  public var blenderRule: [Delivery_BlenderRule] = []

  public var unknownFields = SwiftProtobuf.UnknownStorage()

  public init() {}
}

/// This Event represents a Content being served at a certain position regardless
/// of it was views by a user. Insertions are immutable.
/// Next ID = 16.
public struct Delivery_Insertion {
  // SwiftProtobuf.Message conformance is added in an extension below. See the
  // `Message` and `Message+*Additions` files in the SwiftProtobuf library for
  // methods supported on all messages.

  /// Optional.  If not set, set by API servers.
  public var platformID: UInt64 = 0

  /// Required.
  public var userInfo: Common_UserInfo {
    get {return _userInfo ?? Common_UserInfo()}
    set {_userInfo = newValue}
  }
  /// Returns true if `userInfo` has been explicitly set.
  public var hasUserInfo: Bool {return self._userInfo != nil}
  /// Clears the value of `userInfo`. Subsequent reads from it will return its default value.
  public mutating func clearUserInfo() {self._userInfo = nil}

  /// Optional.  If not set, set by API servers.
  public var timing: Common_Timing {
    get {return _timing ?? Common_Timing()}
    set {_timing = newValue}
  }
  /// Returns true if `timing` has been explicitly set.
  public var hasTiming: Bool {return self._timing != nil}
  /// Clears the value of `timing`. Subsequent reads from it will return its default value.
  public mutating func clearTiming() {self._timing = nil}

  /// Required.  This is a UUID that is generated by the client.
  public var insertionID: String = String()

  /// Optional.
  public var requestID: String = String()

  /// Optional.
  public var viewID: String = String()

  /// Optional.
  public var sessionID: String = String()

  /// Optional.  We'll look this up using the external_content_id.
  public var contentID: String = String()

  /// Optional.  0-based.
  public var position: UInt64 = 0

  /// delivery score
  public var deliveryScore: Double = 0

  /// Optional.  Custom properties per platform.
  public var properties: Common_Properties {
    get {return _properties ?? Common_Properties()}
    set {_properties = newValue}
  }
  /// Returns true if `properties` has been explicitly set.
  public var hasProperties: Bool {return self._properties != nil}
  /// Clears the value of `properties`. Subsequent reads from it will return its default value.
  public mutating func clearProperties() {self._properties = nil}

  public var unknownFields = SwiftProtobuf.UnknownStorage()

  public init() {}

  fileprivate var _userInfo: Common_UserInfo? = nil
  fileprivate var _timing: Common_Timing? = nil
  fileprivate var _properties: Common_Properties? = nil
}

// MARK: - Code below here is support for the SwiftProtobuf runtime.

fileprivate let _protobuf_package = "delivery"

extension Delivery_UseCase: SwiftProtobuf._ProtoNameProviding {
  public static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
    0: .same(proto: "UNKNOWN_USE_CASE"),
    1: .same(proto: "CUSTOM"),
    2: .same(proto: "SEARCH"),
    3: .same(proto: "SEARCH_SUGGESTIONS"),
    4: .same(proto: "FEED"),
    5: .same(proto: "RELATED_CONTENT"),
    6: .same(proto: "CLOSE_UP"),
    7: .same(proto: "CATEGORY_CONTENT"),
    8: .same(proto: "MY_CONTENT"),
    9: .same(proto: "MY_SAVED_CONTENT"),
    10: .same(proto: "SELLER_CONTENT"),
  ]
}

extension Delivery_BlenderRuleType: SwiftProtobuf._ProtoNameProviding {
  public static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
    0: .same(proto: "UNKNOWN_RULE_TYPE"),
    1: .same(proto: "POSITIVE"),
    2: .same(proto: "INSERT"),
    3: .same(proto: "NEGATIVE"),
    4: .same(proto: "DIVERSITY"),
  ]
}

extension Delivery_Request: SwiftProtobuf.Message, SwiftProtobuf._MessageImplementationBase, SwiftProtobuf._ProtoNameProviding {
  public static let protoMessageName: String = _protobuf_package + ".Request"
  public static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
    1: .standard(proto: "platform_id"),
    2: .standard(proto: "user_info"),
    3: .same(proto: "timing"),
    6: .standard(proto: "request_id"),
    7: .standard(proto: "view_id"),
    8: .standard(proto: "session_id"),
    9: .standard(proto: "use_case"),
    10: .standard(proto: "search_query"),
    12: .same(proto: "insertion"),
    13: .standard(proto: "delivery_config"),
    11: .same(proto: "properties"),
  ]

  public mutating func decodeMessage<D: SwiftProtobuf.Decoder>(decoder: inout D) throws {
    while let fieldNumber = try decoder.nextFieldNumber() {
      // The use of inline closures is to circumvent an issue where the compiler
      // allocates stack space for every case branch when no optimizations are
      // enabled. https://github.com/apple/swift-protobuf/issues/1034
      switch fieldNumber {
      case 1: try { try decoder.decodeSingularUInt64Field(value: &self.platformID) }()
      case 2: try { try decoder.decodeSingularMessageField(value: &self._userInfo) }()
      case 3: try { try decoder.decodeSingularMessageField(value: &self._timing) }()
      case 6: try { try decoder.decodeSingularStringField(value: &self.requestID) }()
      case 7: try { try decoder.decodeSingularStringField(value: &self.viewID) }()
      case 8: try { try decoder.decodeSingularStringField(value: &self.sessionID) }()
      case 9: try { try decoder.decodeSingularEnumField(value: &self.useCase) }()
      case 10: try { try decoder.decodeSingularStringField(value: &self.searchQuery) }()
      case 11: try { try decoder.decodeSingularMessageField(value: &self._properties) }()
      case 12: try { try decoder.decodeRepeatedMessageField(value: &self.insertion) }()
      case 13: try { try decoder.decodeSingularMessageField(value: &self._deliveryConfig) }()
      default: break
      }
    }
  }

  public func traverse<V: SwiftProtobuf.Visitor>(visitor: inout V) throws {
    if self.platformID != 0 {
      try visitor.visitSingularUInt64Field(value: self.platformID, fieldNumber: 1)
    }
    if let v = self._userInfo {
      try visitor.visitSingularMessageField(value: v, fieldNumber: 2)
    }
    if let v = self._timing {
      try visitor.visitSingularMessageField(value: v, fieldNumber: 3)
    }
    if !self.requestID.isEmpty {
      try visitor.visitSingularStringField(value: self.requestID, fieldNumber: 6)
    }
    if !self.viewID.isEmpty {
      try visitor.visitSingularStringField(value: self.viewID, fieldNumber: 7)
    }
    if !self.sessionID.isEmpty {
      try visitor.visitSingularStringField(value: self.sessionID, fieldNumber: 8)
    }
    if self.useCase != .unknownUseCase {
      try visitor.visitSingularEnumField(value: self.useCase, fieldNumber: 9)
    }
    if !self.searchQuery.isEmpty {
      try visitor.visitSingularStringField(value: self.searchQuery, fieldNumber: 10)
    }
    if let v = self._properties {
      try visitor.visitSingularMessageField(value: v, fieldNumber: 11)
    }
    if !self.insertion.isEmpty {
      try visitor.visitRepeatedMessageField(value: self.insertion, fieldNumber: 12)
    }
    if let v = self._deliveryConfig {
      try visitor.visitSingularMessageField(value: v, fieldNumber: 13)
    }
    try unknownFields.traverse(visitor: &visitor)
  }

  public static func ==(lhs: Delivery_Request, rhs: Delivery_Request) -> Bool {
    if lhs.platformID != rhs.platformID {return false}
    if lhs._userInfo != rhs._userInfo {return false}
    if lhs._timing != rhs._timing {return false}
    if lhs.requestID != rhs.requestID {return false}
    if lhs.viewID != rhs.viewID {return false}
    if lhs.sessionID != rhs.sessionID {return false}
    if lhs.useCase != rhs.useCase {return false}
    if lhs.searchQuery != rhs.searchQuery {return false}
    if lhs.insertion != rhs.insertion {return false}
    if lhs._deliveryConfig != rhs._deliveryConfig {return false}
    if lhs._properties != rhs._properties {return false}
    if lhs.unknownFields != rhs.unknownFields {return false}
    return true
  }
}

extension Delivery_Response: SwiftProtobuf.Message, SwiftProtobuf._MessageImplementationBase, SwiftProtobuf._ProtoNameProviding {
  public static let protoMessageName: String = _protobuf_package + ".Response"
  public static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
    2: .same(proto: "insertion"),
  ]

  public mutating func decodeMessage<D: SwiftProtobuf.Decoder>(decoder: inout D) throws {
    while let fieldNumber = try decoder.nextFieldNumber() {
      // The use of inline closures is to circumvent an issue where the compiler
      // allocates stack space for every case branch when no optimizations are
      // enabled. https://github.com/apple/swift-protobuf/issues/1034
      switch fieldNumber {
      case 2: try { try decoder.decodeRepeatedMessageField(value: &self.insertion) }()
      default: break
      }
    }
  }

  public func traverse<V: SwiftProtobuf.Visitor>(visitor: inout V) throws {
    if !self.insertion.isEmpty {
      try visitor.visitRepeatedMessageField(value: self.insertion, fieldNumber: 2)
    }
    try unknownFields.traverse(visitor: &visitor)
  }

  public static func ==(lhs: Delivery_Response, rhs: Delivery_Response) -> Bool {
    if lhs.insertion != rhs.insertion {return false}
    if lhs.unknownFields != rhs.unknownFields {return false}
    return true
  }
}

extension Delivery_BlenderRule: SwiftProtobuf.Message, SwiftProtobuf._MessageImplementationBase, SwiftProtobuf._ProtoNameProviding {
  public static let protoMessageName: String = _protobuf_package + ".BlenderRule"
  public static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
    1: .standard(proto: "rule_type"),
    2: .same(proto: "priority"),
    3: .same(proto: "properties"),
  ]

  public mutating func decodeMessage<D: SwiftProtobuf.Decoder>(decoder: inout D) throws {
    while let fieldNumber = try decoder.nextFieldNumber() {
      // The use of inline closures is to circumvent an issue where the compiler
      // allocates stack space for every case branch when no optimizations are
      // enabled. https://github.com/apple/swift-protobuf/issues/1034
      switch fieldNumber {
      case 1: try { try decoder.decodeSingularEnumField(value: &self.ruleType) }()
      case 2: try { try decoder.decodeSingularUInt32Field(value: &self.priority) }()
      case 3: try { try decoder.decodeSingularMessageField(value: &self._properties) }()
      default: break
      }
    }
  }

  public func traverse<V: SwiftProtobuf.Visitor>(visitor: inout V) throws {
    if self.ruleType != .unknownRuleType {
      try visitor.visitSingularEnumField(value: self.ruleType, fieldNumber: 1)
    }
    if self.priority != 0 {
      try visitor.visitSingularUInt32Field(value: self.priority, fieldNumber: 2)
    }
    if let v = self._properties {
      try visitor.visitSingularMessageField(value: v, fieldNumber: 3)
    }
    try unknownFields.traverse(visitor: &visitor)
  }

  public static func ==(lhs: Delivery_BlenderRule, rhs: Delivery_BlenderRule) -> Bool {
    if lhs.ruleType != rhs.ruleType {return false}
    if lhs.priority != rhs.priority {return false}
    if lhs._properties != rhs._properties {return false}
    if lhs.unknownFields != rhs.unknownFields {return false}
    return true
  }
}

extension Delivery_DeliveryConfig: SwiftProtobuf.Message, SwiftProtobuf._MessageImplementationBase, SwiftProtobuf._ProtoNameProviding {
  public static let protoMessageName: String = _protobuf_package + ".DeliveryConfig"
  public static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
    1: .standard(proto: "blender_rule"),
  ]

  public mutating func decodeMessage<D: SwiftProtobuf.Decoder>(decoder: inout D) throws {
    while let fieldNumber = try decoder.nextFieldNumber() {
      // The use of inline closures is to circumvent an issue where the compiler
      // allocates stack space for every case branch when no optimizations are
      // enabled. https://github.com/apple/swift-protobuf/issues/1034
      switch fieldNumber {
      case 1: try { try decoder.decodeRepeatedMessageField(value: &self.blenderRule) }()
      default: break
      }
    }
  }

  public func traverse<V: SwiftProtobuf.Visitor>(visitor: inout V) throws {
    if !self.blenderRule.isEmpty {
      try visitor.visitRepeatedMessageField(value: self.blenderRule, fieldNumber: 1)
    }
    try unknownFields.traverse(visitor: &visitor)
  }

  public static func ==(lhs: Delivery_DeliveryConfig, rhs: Delivery_DeliveryConfig) -> Bool {
    if lhs.blenderRule != rhs.blenderRule {return false}
    if lhs.unknownFields != rhs.unknownFields {return false}
    return true
  }
}

extension Delivery_Insertion: SwiftProtobuf.Message, SwiftProtobuf._MessageImplementationBase, SwiftProtobuf._ProtoNameProviding {
  public static let protoMessageName: String = _protobuf_package + ".Insertion"
  public static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
    1: .standard(proto: "platform_id"),
    2: .standard(proto: "user_info"),
    3: .same(proto: "timing"),
    6: .standard(proto: "insertion_id"),
    7: .standard(proto: "request_id"),
    9: .standard(proto: "view_id"),
    8: .standard(proto: "session_id"),
    10: .standard(proto: "content_id"),
    12: .same(proto: "position"),
    15: .standard(proto: "delivery_score"),
    13: .same(proto: "properties"),
  ]

  public mutating func decodeMessage<D: SwiftProtobuf.Decoder>(decoder: inout D) throws {
    while let fieldNumber = try decoder.nextFieldNumber() {
      // The use of inline closures is to circumvent an issue where the compiler
      // allocates stack space for every case branch when no optimizations are
      // enabled. https://github.com/apple/swift-protobuf/issues/1034
      switch fieldNumber {
      case 1: try { try decoder.decodeSingularUInt64Field(value: &self.platformID) }()
      case 2: try { try decoder.decodeSingularMessageField(value: &self._userInfo) }()
      case 3: try { try decoder.decodeSingularMessageField(value: &self._timing) }()
      case 6: try { try decoder.decodeSingularStringField(value: &self.insertionID) }()
      case 7: try { try decoder.decodeSingularStringField(value: &self.requestID) }()
      case 8: try { try decoder.decodeSingularStringField(value: &self.sessionID) }()
      case 9: try { try decoder.decodeSingularStringField(value: &self.viewID) }()
      case 10: try { try decoder.decodeSingularStringField(value: &self.contentID) }()
      case 12: try { try decoder.decodeSingularUInt64Field(value: &self.position) }()
      case 13: try { try decoder.decodeSingularMessageField(value: &self._properties) }()
      case 15: try { try decoder.decodeSingularDoubleField(value: &self.deliveryScore) }()
      default: break
      }
    }
  }

  public func traverse<V: SwiftProtobuf.Visitor>(visitor: inout V) throws {
    if self.platformID != 0 {
      try visitor.visitSingularUInt64Field(value: self.platformID, fieldNumber: 1)
    }
    if let v = self._userInfo {
      try visitor.visitSingularMessageField(value: v, fieldNumber: 2)
    }
    if let v = self._timing {
      try visitor.visitSingularMessageField(value: v, fieldNumber: 3)
    }
    if !self.insertionID.isEmpty {
      try visitor.visitSingularStringField(value: self.insertionID, fieldNumber: 6)
    }
    if !self.requestID.isEmpty {
      try visitor.visitSingularStringField(value: self.requestID, fieldNumber: 7)
    }
    if !self.sessionID.isEmpty {
      try visitor.visitSingularStringField(value: self.sessionID, fieldNumber: 8)
    }
    if !self.viewID.isEmpty {
      try visitor.visitSingularStringField(value: self.viewID, fieldNumber: 9)
    }
    if !self.contentID.isEmpty {
      try visitor.visitSingularStringField(value: self.contentID, fieldNumber: 10)
    }
    if self.position != 0 {
      try visitor.visitSingularUInt64Field(value: self.position, fieldNumber: 12)
    }
    if let v = self._properties {
      try visitor.visitSingularMessageField(value: v, fieldNumber: 13)
    }
    if self.deliveryScore != 0 {
      try visitor.visitSingularDoubleField(value: self.deliveryScore, fieldNumber: 15)
    }
    try unknownFields.traverse(visitor: &visitor)
  }

  public static func ==(lhs: Delivery_Insertion, rhs: Delivery_Insertion) -> Bool {
    if lhs.platformID != rhs.platformID {return false}
    if lhs._userInfo != rhs._userInfo {return false}
    if lhs._timing != rhs._timing {return false}
    if lhs.insertionID != rhs.insertionID {return false}
    if lhs.requestID != rhs.requestID {return false}
    if lhs.viewID != rhs.viewID {return false}
    if lhs.sessionID != rhs.sessionID {return false}
    if lhs.contentID != rhs.contentID {return false}
    if lhs.position != rhs.position {return false}
    if lhs.deliveryScore != rhs.deliveryScore {return false}
    if lhs._properties != rhs._properties {return false}
    if lhs.unknownFields != rhs.unknownFields {return false}
    return true
  }
}

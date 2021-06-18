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
/// Next ID = 12.
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
  case discover // = 11
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
    case 11: self = .discover
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
    case .discover: return 11
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
    .discover,
  ]
}

#endif  // swift(>=4.2)

/// Represents a Request for Insertions (Content).
/// Can be used to log existing ranking (not Promoted) or Promoted's Delivery
/// API requests.
///
/// Next ID = 18.
public struct Delivery_Request {
  // SwiftProtobuf.Message conformance is added in an extension below. See the
  // `Message` and `Message+*Additions` files in the SwiftProtobuf library for
  // methods supported on all messages.

  /// Optional.  If not set, set by API servers.
  /// If not set, API server uses LogRequest.platform_id.
  public var platformID: UInt64 {
    get {return _storage._platformID}
    set {_uniqueStorage()._platformID = newValue}
  }

  /// Optional.  Must be set on LogRequest or here.
  public var userInfo: Common_UserInfo {
    get {return _storage._userInfo ?? Common_UserInfo()}
    set {_uniqueStorage()._userInfo = newValue}
  }
  /// Returns true if `userInfo` has been explicitly set.
  public var hasUserInfo: Bool {return _storage._userInfo != nil}
  /// Clears the value of `userInfo`. Subsequent reads from it will return its default value.
  public mutating func clearUserInfo() {_uniqueStorage()._userInfo = nil}

  /// Optional.  If not set, set by API servers.
  /// If not set, API server uses LogRequest.timing.
  public var timing: Common_Timing {
    get {return _storage._timing ?? Common_Timing()}
    set {_uniqueStorage()._timing = newValue}
  }
  /// Returns true if `timing` has been explicitly set.
  public var hasTiming: Bool {return _storage._timing != nil}
  /// Clears the value of `timing`. Subsequent reads from it will return its default value.
  public mutating func clearTiming() {_uniqueStorage()._timing = nil}

  /// Optional.  If not set, API server uses LogRequest.client_info.
  public var clientInfo: Common_ClientInfo {
    get {return _storage._clientInfo ?? Common_ClientInfo()}
    set {_uniqueStorage()._clientInfo = newValue}
  }
  /// Returns true if `clientInfo` has been explicitly set.
  public var hasClientInfo: Bool {return _storage._clientInfo != nil}
  /// Clears the value of `clientInfo`. Subsequent reads from it will return its default value.
  public mutating func clearClientInfo() {_uniqueStorage()._clientInfo = nil}

  /// Optional.  Primary key.
  /// SDKs usually handles this automatically. For details, see
  /// https://github.com/promotedai/schema#setting-primary-keys
  public var requestID: String {
    get {return _storage._requestID}
    set {_uniqueStorage()._requestID = newValue}
  }

  /// Required.
  public var viewID: String {
    get {return _storage._viewID}
    set {_uniqueStorage()._viewID = newValue}
  }

  /// Optional.
  public var sessionID: String {
    get {return _storage._sessionID}
    set {_uniqueStorage()._sessionID = newValue}
  }

  /// Optional.
  /// An ID indicating the client's version of a request_id.  This field
  /// matters when a single Request from the client could cause multiple
  /// request executions (e.g. backups from retries or timeouts).  Each of those
  /// request executions should have separate request_ids.
  /// This should be a UUID.  If not set on a Request, the SDKs or Promoted
  /// servers will set it.
  public var clientRequestID: String {
    get {return _storage._clientRequestID}
    set {_uniqueStorage()._clientRequestID = newValue}
  }

  /// Optional.
  public var useCase: Delivery_UseCase {
    get {return _storage._useCase}
    set {_uniqueStorage()._useCase = newValue}
  }

  /// Optional.
  public var searchQuery: String {
    get {return _storage._searchQuery}
    set {_uniqueStorage()._searchQuery = newValue}
  }

  /// Optional. Number of Insertions to return.
  /// DEPRECATED: use paging intead.
  public var limit: Int32 {
    get {return _storage._limit}
    set {_uniqueStorage()._limit = newValue}
  }

  /// Optional. Set to request a specific "page" of results.
  public var paging: Delivery_Paging {
    get {return _storage._paging ?? Delivery_Paging()}
    set {_uniqueStorage()._paging = newValue}
  }
  /// Returns true if `paging` has been explicitly set.
  public var hasPaging: Bool {return _storage._paging != nil}
  /// Clears the value of `paging`. Subsequent reads from it will return its default value.
  public mutating func clearPaging() {_uniqueStorage()._paging = nil}

  /// Optional.
  /// If set in Delivery API, Promoted will re-rank this list of Content.
  /// This list can be used to pass in a list of Content (or Content IDs).
  /// If set in Metrics API, Promoted will separate this list of Insertions
  /// into separate log records.
  public var insertion: [Delivery_Insertion] {
    get {return _storage._insertion}
    set {_uniqueStorage()._insertion = newValue}
  }

  /// Optional.
  public var blenderConfig: Delivery_BlenderConfig {
    get {return _storage._blenderConfig ?? Delivery_BlenderConfig()}
    set {_uniqueStorage()._blenderConfig = newValue}
  }
  /// Returns true if `blenderConfig` has been explicitly set.
  public var hasBlenderConfig: Bool {return _storage._blenderConfig != nil}
  /// Clears the value of `blenderConfig`. Subsequent reads from it will return its default value.
  public mutating func clearBlenderConfig() {_uniqueStorage()._blenderConfig = nil}

  /// Optional.  Custom properties per platform.
  public var properties: Common_Properties {
    get {return _storage._properties ?? Common_Properties()}
    set {_uniqueStorage()._properties = newValue}
  }
  /// Returns true if `properties` has been explicitly set.
  public var hasProperties: Bool {return _storage._properties != nil}
  /// Clears the value of `properties`. Subsequent reads from it will return its default value.
  public mutating func clearProperties() {_uniqueStorage()._properties = nil}

  public var unknownFields = SwiftProtobuf.UnknownStorage()

  public init() {}

  fileprivate var _storage = _StorageClass.defaultInstance
}

/// Next ID = 5.
public struct Delivery_Paging {
  // SwiftProtobuf.Message conformance is added in an extension below. See the
  // `Message` and `Message+*Additions` files in the SwiftProtobuf library for
  // methods supported on all messages.

  /// Identity for the paging request (opaque token).
  /// A single paging_id will have many associated requests to get the fully
  /// paged response set (hence, many request_id's and client_request_id's).
  ///
  /// Required if using the cursor for the last_index; optional if using offset.
  /// Setting this value provides better paging consistency/stability.  Ideally,
  /// it should be set from the initial paging response
  /// (Response.paging_info.paging_id).
  ///
  /// An external value can be used when *not* using promoted.ai's item
  /// datastore.  The value must be specific enough to be globally unique, yet
  /// general enough to ignore paging parameters.  A good example of a useful,
  /// externally set paging_id is to use the paging token or identifiers returned
  /// by your item datastore retrieval while passing the eligible insertions in
  /// the Request.  If in doubt, rely on the Response.paging_info.paging_id or
  /// contact us.
  public var pagingID: String = String()

  /// Required.  The number of items (insertions) to return.
  public var size: Int32 = 0

  /// Required.  The position of the first item of this page.
  /// For example, to get the 5th page of results with a paging size of 10:
  /// * cursor is an opaque token, so it should be the value returned
  ///   by the 4th page response (Response.paging_info.cursor).
  /// * offset is a 0-based index, so it should be set to 40.
  public var starting: Delivery_Paging.OneOf_Starting? = nil

  public var cursor: String {
    get {
      if case .cursor(let v)? = starting {return v}
      return String()
    }
    set {starting = .cursor(newValue)}
  }

  public var offset: Int32 {
    get {
      if case .offset(let v)? = starting {return v}
      return 0
    }
    set {starting = .offset(newValue)}
  }

  public var unknownFields = SwiftProtobuf.UnknownStorage()

  /// Required.  The position of the first item of this page.
  /// For example, to get the 5th page of results with a paging size of 10:
  /// * cursor is an opaque token, so it should be the value returned
  ///   by the 4th page response (Response.paging_info.cursor).
  /// * offset is a 0-based index, so it should be set to 40.
  public enum OneOf_Starting: Equatable {
    case cursor(String)
    case offset(Int32)

  #if !swift(>=4.1)
    public static func ==(lhs: Delivery_Paging.OneOf_Starting, rhs: Delivery_Paging.OneOf_Starting) -> Bool {
      // The use of inline closures is to circumvent an issue where the compiler
      // allocates stack space for every case branch when no optimizations are
      // enabled. https://github.com/apple/swift-protobuf/issues/1034
      switch (lhs, rhs) {
      case (.cursor, .cursor): return {
        guard case .cursor(let l) = lhs, case .cursor(let r) = rhs else { preconditionFailure() }
        return l == r
      }()
      case (.offset, .offset): return {
        guard case .offset(let l) = lhs, case .offset(let r) = rhs else { preconditionFailure() }
        return l == r
      }()
      default: return false
      }
    }
  #endif
  }

  public init() {}
}

/// Next ID = 4.
public struct Delivery_Response {
  // SwiftProtobuf.Message conformance is added in an extension below. See the
  // `Message` and `Message+*Additions` files in the SwiftProtobuf library for
  // methods supported on all messages.

  /// List of content.
  public var insertion: [Delivery_Insertion] = []

  /// Paging information of this response.  Only returned on paging requests.
  public var pagingInfo: Delivery_PagingInfo {
    get {return _pagingInfo ?? Delivery_PagingInfo()}
    set {_pagingInfo = newValue}
  }
  /// Returns true if `pagingInfo` has been explicitly set.
  public var hasPagingInfo: Bool {return self._pagingInfo != nil}
  /// Clears the value of `pagingInfo`. Subsequent reads from it will return its default value.
  public mutating func clearPagingInfo() {self._pagingInfo = nil}

  public var unknownFields = SwiftProtobuf.UnknownStorage()

  public init() {}

  fileprivate var _pagingInfo: Delivery_PagingInfo? = nil
}

/// Next ID = 3.
public struct Delivery_PagingInfo {
  // SwiftProtobuf.Message conformance is added in an extension below. See the
  // `Message` and `Message+*Additions` files in the SwiftProtobuf library for
  // methods supported on all messages.

  /// Opaque identifier to be used in subsequent paging requests for a specific
  /// paged repsonse set.
  public var pagingID: String = String()

  /// Opaque token that represents the last item index of this response.
  public var cursor: String = String()

  public var unknownFields = SwiftProtobuf.UnknownStorage()

  public init() {}
}

/// This Event represents a Content being served at a certain position regardless
/// of it was views by a user. Insertions are immutable.
/// Next ID = 17.
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

  /// Optional.  If not set, API server uses LogRequest.client_info.
  public var clientInfo: Common_ClientInfo {
    get {return _clientInfo ?? Common_ClientInfo()}
    set {_clientInfo = newValue}
  }
  /// Returns true if `clientInfo` has been explicitly set.
  public var hasClientInfo: Bool {return self._clientInfo != nil}
  /// Clears the value of `clientInfo`. Subsequent reads from it will return its default value.
  public mutating func clearClientInfo() {self._clientInfo = nil}

  /// Optional.  Primary key.
  /// SDKs usually handles this automatically. For details, see
  /// https://github.com/promotedai/schema#setting-primary-keys
  public var insertionID: String = String()

  /// Optional.
  public var requestID: String = String()

  /// Optional.
  public var viewID: String = String()

  /// Optional.
  public var sessionID: String = String()

  /// Optional.  We'll look this up using the external_content_id.
  public var contentID: String = String()

  /// Optional.  0-based. As set by the customer, not by Promoted allocation.
  public var position: UInt64 = 0

  /// Optional. Custom item attributes and features set by customers.
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
  fileprivate var _clientInfo: Common_ClientInfo? = nil
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
    11: .same(proto: "DISCOVER"),
  ]
}

extension Delivery_Request: SwiftProtobuf.Message, SwiftProtobuf._MessageImplementationBase, SwiftProtobuf._ProtoNameProviding {
  public static let protoMessageName: String = _protobuf_package + ".Request"
  public static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
    1: .standard(proto: "platform_id"),
    2: .standard(proto: "user_info"),
    3: .same(proto: "timing"),
    4: .standard(proto: "client_info"),
    6: .standard(proto: "request_id"),
    7: .standard(proto: "view_id"),
    8: .standard(proto: "session_id"),
    14: .standard(proto: "client_request_id"),
    9: .standard(proto: "use_case"),
    10: .standard(proto: "search_query"),
    15: .same(proto: "limit"),
    17: .same(proto: "paging"),
    11: .same(proto: "insertion"),
    12: .standard(proto: "blender_config"),
    13: .same(proto: "properties"),
  ]

  fileprivate class _StorageClass {
    var _platformID: UInt64 = 0
    var _userInfo: Common_UserInfo? = nil
    var _timing: Common_Timing? = nil
    var _clientInfo: Common_ClientInfo? = nil
    var _requestID: String = String()
    var _viewID: String = String()
    var _sessionID: String = String()
    var _clientRequestID: String = String()
    var _useCase: Delivery_UseCase = .unknownUseCase
    var _searchQuery: String = String()
    var _limit: Int32 = 0
    var _paging: Delivery_Paging? = nil
    var _insertion: [Delivery_Insertion] = []
    var _blenderConfig: Delivery_BlenderConfig? = nil
    var _properties: Common_Properties? = nil

    static let defaultInstance = _StorageClass()

    private init() {}

    init(copying source: _StorageClass) {
      _platformID = source._platformID
      _userInfo = source._userInfo
      _timing = source._timing
      _clientInfo = source._clientInfo
      _requestID = source._requestID
      _viewID = source._viewID
      _sessionID = source._sessionID
      _clientRequestID = source._clientRequestID
      _useCase = source._useCase
      _searchQuery = source._searchQuery
      _limit = source._limit
      _paging = source._paging
      _insertion = source._insertion
      _blenderConfig = source._blenderConfig
      _properties = source._properties
    }
  }

  fileprivate mutating func _uniqueStorage() -> _StorageClass {
    if !isKnownUniquelyReferenced(&_storage) {
      _storage = _StorageClass(copying: _storage)
    }
    return _storage
  }

  public mutating func decodeMessage<D: SwiftProtobuf.Decoder>(decoder: inout D) throws {
    _ = _uniqueStorage()
    try withExtendedLifetime(_storage) { (_storage: _StorageClass) in
      while let fieldNumber = try decoder.nextFieldNumber() {
        // The use of inline closures is to circumvent an issue where the compiler
        // allocates stack space for every case branch when no optimizations are
        // enabled. https://github.com/apple/swift-protobuf/issues/1034
        switch fieldNumber {
        case 1: try { try decoder.decodeSingularUInt64Field(value: &_storage._platformID) }()
        case 2: try { try decoder.decodeSingularMessageField(value: &_storage._userInfo) }()
        case 3: try { try decoder.decodeSingularMessageField(value: &_storage._timing) }()
        case 4: try { try decoder.decodeSingularMessageField(value: &_storage._clientInfo) }()
        case 6: try { try decoder.decodeSingularStringField(value: &_storage._requestID) }()
        case 7: try { try decoder.decodeSingularStringField(value: &_storage._viewID) }()
        case 8: try { try decoder.decodeSingularStringField(value: &_storage._sessionID) }()
        case 9: try { try decoder.decodeSingularEnumField(value: &_storage._useCase) }()
        case 10: try { try decoder.decodeSingularStringField(value: &_storage._searchQuery) }()
        case 11: try { try decoder.decodeRepeatedMessageField(value: &_storage._insertion) }()
        case 12: try { try decoder.decodeSingularMessageField(value: &_storage._blenderConfig) }()
        case 13: try { try decoder.decodeSingularMessageField(value: &_storage._properties) }()
        case 14: try { try decoder.decodeSingularStringField(value: &_storage._clientRequestID) }()
        case 15: try { try decoder.decodeSingularInt32Field(value: &_storage._limit) }()
        case 17: try { try decoder.decodeSingularMessageField(value: &_storage._paging) }()
        default: break
        }
      }
    }
  }

  public func traverse<V: SwiftProtobuf.Visitor>(visitor: inout V) throws {
    try withExtendedLifetime(_storage) { (_storage: _StorageClass) in
      if _storage._platformID != 0 {
        try visitor.visitSingularUInt64Field(value: _storage._platformID, fieldNumber: 1)
      }
      if let v = _storage._userInfo {
        try visitor.visitSingularMessageField(value: v, fieldNumber: 2)
      }
      if let v = _storage._timing {
        try visitor.visitSingularMessageField(value: v, fieldNumber: 3)
      }
      if let v = _storage._clientInfo {
        try visitor.visitSingularMessageField(value: v, fieldNumber: 4)
      }
      if !_storage._requestID.isEmpty {
        try visitor.visitSingularStringField(value: _storage._requestID, fieldNumber: 6)
      }
      if !_storage._viewID.isEmpty {
        try visitor.visitSingularStringField(value: _storage._viewID, fieldNumber: 7)
      }
      if !_storage._sessionID.isEmpty {
        try visitor.visitSingularStringField(value: _storage._sessionID, fieldNumber: 8)
      }
      if _storage._useCase != .unknownUseCase {
        try visitor.visitSingularEnumField(value: _storage._useCase, fieldNumber: 9)
      }
      if !_storage._searchQuery.isEmpty {
        try visitor.visitSingularStringField(value: _storage._searchQuery, fieldNumber: 10)
      }
      if !_storage._insertion.isEmpty {
        try visitor.visitRepeatedMessageField(value: _storage._insertion, fieldNumber: 11)
      }
      if let v = _storage._blenderConfig {
        try visitor.visitSingularMessageField(value: v, fieldNumber: 12)
      }
      if let v = _storage._properties {
        try visitor.visitSingularMessageField(value: v, fieldNumber: 13)
      }
      if !_storage._clientRequestID.isEmpty {
        try visitor.visitSingularStringField(value: _storage._clientRequestID, fieldNumber: 14)
      }
      if _storage._limit != 0 {
        try visitor.visitSingularInt32Field(value: _storage._limit, fieldNumber: 15)
      }
      if let v = _storage._paging {
        try visitor.visitSingularMessageField(value: v, fieldNumber: 17)
      }
    }
    try unknownFields.traverse(visitor: &visitor)
  }

  public static func ==(lhs: Delivery_Request, rhs: Delivery_Request) -> Bool {
    if lhs._storage !== rhs._storage {
      let storagesAreEqual: Bool = withExtendedLifetime((lhs._storage, rhs._storage)) { (_args: (_StorageClass, _StorageClass)) in
        let _storage = _args.0
        let rhs_storage = _args.1
        if _storage._platformID != rhs_storage._platformID {return false}
        if _storage._userInfo != rhs_storage._userInfo {return false}
        if _storage._timing != rhs_storage._timing {return false}
        if _storage._clientInfo != rhs_storage._clientInfo {return false}
        if _storage._requestID != rhs_storage._requestID {return false}
        if _storage._viewID != rhs_storage._viewID {return false}
        if _storage._sessionID != rhs_storage._sessionID {return false}
        if _storage._clientRequestID != rhs_storage._clientRequestID {return false}
        if _storage._useCase != rhs_storage._useCase {return false}
        if _storage._searchQuery != rhs_storage._searchQuery {return false}
        if _storage._limit != rhs_storage._limit {return false}
        if _storage._paging != rhs_storage._paging {return false}
        if _storage._insertion != rhs_storage._insertion {return false}
        if _storage._blenderConfig != rhs_storage._blenderConfig {return false}
        if _storage._properties != rhs_storage._properties {return false}
        return true
      }
      if !storagesAreEqual {return false}
    }
    if lhs.unknownFields != rhs.unknownFields {return false}
    return true
  }
}

extension Delivery_Paging: SwiftProtobuf.Message, SwiftProtobuf._MessageImplementationBase, SwiftProtobuf._ProtoNameProviding {
  public static let protoMessageName: String = _protobuf_package + ".Paging"
  public static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
    1: .standard(proto: "paging_id"),
    2: .same(proto: "size"),
    3: .same(proto: "cursor"),
    4: .same(proto: "offset"),
  ]

  public mutating func decodeMessage<D: SwiftProtobuf.Decoder>(decoder: inout D) throws {
    while let fieldNumber = try decoder.nextFieldNumber() {
      // The use of inline closures is to circumvent an issue where the compiler
      // allocates stack space for every case branch when no optimizations are
      // enabled. https://github.com/apple/swift-protobuf/issues/1034
      switch fieldNumber {
      case 1: try { try decoder.decodeSingularStringField(value: &self.pagingID) }()
      case 2: try { try decoder.decodeSingularInt32Field(value: &self.size) }()
      case 3: try {
        if self.starting != nil {try decoder.handleConflictingOneOf()}
        var v: String?
        try decoder.decodeSingularStringField(value: &v)
        if let v = v {self.starting = .cursor(v)}
      }()
      case 4: try {
        if self.starting != nil {try decoder.handleConflictingOneOf()}
        var v: Int32?
        try decoder.decodeSingularInt32Field(value: &v)
        if let v = v {self.starting = .offset(v)}
      }()
      default: break
      }
    }
  }

  public func traverse<V: SwiftProtobuf.Visitor>(visitor: inout V) throws {
    if !self.pagingID.isEmpty {
      try visitor.visitSingularStringField(value: self.pagingID, fieldNumber: 1)
    }
    if self.size != 0 {
      try visitor.visitSingularInt32Field(value: self.size, fieldNumber: 2)
    }
    // The use of inline closures is to circumvent an issue where the compiler
    // allocates stack space for every case branch when no optimizations are
    // enabled. https://github.com/apple/swift-protobuf/issues/1034
    switch self.starting {
    case .cursor?: try {
      guard case .cursor(let v)? = self.starting else { preconditionFailure() }
      try visitor.visitSingularStringField(value: v, fieldNumber: 3)
    }()
    case .offset?: try {
      guard case .offset(let v)? = self.starting else { preconditionFailure() }
      try visitor.visitSingularInt32Field(value: v, fieldNumber: 4)
    }()
    case nil: break
    }
    try unknownFields.traverse(visitor: &visitor)
  }

  public static func ==(lhs: Delivery_Paging, rhs: Delivery_Paging) -> Bool {
    if lhs.pagingID != rhs.pagingID {return false}
    if lhs.size != rhs.size {return false}
    if lhs.starting != rhs.starting {return false}
    if lhs.unknownFields != rhs.unknownFields {return false}
    return true
  }
}

extension Delivery_Response: SwiftProtobuf.Message, SwiftProtobuf._MessageImplementationBase, SwiftProtobuf._ProtoNameProviding {
  public static let protoMessageName: String = _protobuf_package + ".Response"
  public static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
    2: .same(proto: "insertion"),
    3: .standard(proto: "paging_info"),
  ]

  public mutating func decodeMessage<D: SwiftProtobuf.Decoder>(decoder: inout D) throws {
    while let fieldNumber = try decoder.nextFieldNumber() {
      // The use of inline closures is to circumvent an issue where the compiler
      // allocates stack space for every case branch when no optimizations are
      // enabled. https://github.com/apple/swift-protobuf/issues/1034
      switch fieldNumber {
      case 2: try { try decoder.decodeRepeatedMessageField(value: &self.insertion) }()
      case 3: try { try decoder.decodeSingularMessageField(value: &self._pagingInfo) }()
      default: break
      }
    }
  }

  public func traverse<V: SwiftProtobuf.Visitor>(visitor: inout V) throws {
    if !self.insertion.isEmpty {
      try visitor.visitRepeatedMessageField(value: self.insertion, fieldNumber: 2)
    }
    if let v = self._pagingInfo {
      try visitor.visitSingularMessageField(value: v, fieldNumber: 3)
    }
    try unknownFields.traverse(visitor: &visitor)
  }

  public static func ==(lhs: Delivery_Response, rhs: Delivery_Response) -> Bool {
    if lhs.insertion != rhs.insertion {return false}
    if lhs._pagingInfo != rhs._pagingInfo {return false}
    if lhs.unknownFields != rhs.unknownFields {return false}
    return true
  }
}

extension Delivery_PagingInfo: SwiftProtobuf.Message, SwiftProtobuf._MessageImplementationBase, SwiftProtobuf._ProtoNameProviding {
  public static let protoMessageName: String = _protobuf_package + ".PagingInfo"
  public static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
    1: .standard(proto: "paging_id"),
    2: .same(proto: "cursor"),
  ]

  public mutating func decodeMessage<D: SwiftProtobuf.Decoder>(decoder: inout D) throws {
    while let fieldNumber = try decoder.nextFieldNumber() {
      // The use of inline closures is to circumvent an issue where the compiler
      // allocates stack space for every case branch when no optimizations are
      // enabled. https://github.com/apple/swift-protobuf/issues/1034
      switch fieldNumber {
      case 1: try { try decoder.decodeSingularStringField(value: &self.pagingID) }()
      case 2: try { try decoder.decodeSingularStringField(value: &self.cursor) }()
      default: break
      }
    }
  }

  public func traverse<V: SwiftProtobuf.Visitor>(visitor: inout V) throws {
    if !self.pagingID.isEmpty {
      try visitor.visitSingularStringField(value: self.pagingID, fieldNumber: 1)
    }
    if !self.cursor.isEmpty {
      try visitor.visitSingularStringField(value: self.cursor, fieldNumber: 2)
    }
    try unknownFields.traverse(visitor: &visitor)
  }

  public static func ==(lhs: Delivery_PagingInfo, rhs: Delivery_PagingInfo) -> Bool {
    if lhs.pagingID != rhs.pagingID {return false}
    if lhs.cursor != rhs.cursor {return false}
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
    4: .standard(proto: "client_info"),
    6: .standard(proto: "insertion_id"),
    7: .standard(proto: "request_id"),
    9: .standard(proto: "view_id"),
    8: .standard(proto: "session_id"),
    10: .standard(proto: "content_id"),
    12: .same(proto: "position"),
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
      case 4: try { try decoder.decodeSingularMessageField(value: &self._clientInfo) }()
      case 6: try { try decoder.decodeSingularStringField(value: &self.insertionID) }()
      case 7: try { try decoder.decodeSingularStringField(value: &self.requestID) }()
      case 8: try { try decoder.decodeSingularStringField(value: &self.sessionID) }()
      case 9: try { try decoder.decodeSingularStringField(value: &self.viewID) }()
      case 10: try { try decoder.decodeSingularStringField(value: &self.contentID) }()
      case 12: try { try decoder.decodeSingularUInt64Field(value: &self.position) }()
      case 13: try { try decoder.decodeSingularMessageField(value: &self._properties) }()
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
    if let v = self._clientInfo {
      try visitor.visitSingularMessageField(value: v, fieldNumber: 4)
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
    try unknownFields.traverse(visitor: &visitor)
  }

  public static func ==(lhs: Delivery_Insertion, rhs: Delivery_Insertion) -> Bool {
    if lhs.platformID != rhs.platformID {return false}
    if lhs._userInfo != rhs._userInfo {return false}
    if lhs._timing != rhs._timing {return false}
    if lhs._clientInfo != rhs._clientInfo {return false}
    if lhs.insertionID != rhs.insertionID {return false}
    if lhs.requestID != rhs.requestID {return false}
    if lhs.viewID != rhs.viewID {return false}
    if lhs.sessionID != rhs.sessionID {return false}
    if lhs.contentID != rhs.contentID {return false}
    if lhs.position != rhs.position {return false}
    if lhs._properties != rhs._properties {return false}
    if lhs.unknownFields != rhs.unknownFields {return false}
    return true
  }
}

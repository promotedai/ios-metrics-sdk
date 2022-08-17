import Foundation
import SwiftProtobuf

public enum PropertyValue:
  ExpressibleByIntegerLiteral,
  ExpressibleByStringLiteral,
  ExpressibleByBooleanLiteral,
  ExpressibleByFloatLiteral,
  ExpressibleByArrayLiteral {

  public typealias StringLiteralType = String
  public typealias ArrayLiteralElement = PropertyValue

  case int(Int)
  case string(String)
  case bool(Bool)
  case float(Float)
  case array([PropertyValue])

  public static func value(for rawValue: Any?) -> PropertyValue? {
    guard let rawValue = rawValue else { return nil }
    switch rawValue {
    case let intValue as Int: return .int(intValue)
    case let stringValue as String: return .string(stringValue)
    case let boolValue as Bool: return .bool(boolValue)
    case let floatValue as Float: return .float(floatValue)
    case let arrayValue as Array<PropertyValue>: return .array(arrayValue)
    default: return nil
    }
  }

  public var rawValue: Any {
    switch self {
    case .int(let intValue): return intValue
    case .string(let stringValue): return stringValue
    case .bool(let boolValue): return boolValue
    case .float(let floatValue): return floatValue
    case .array(let arrayValue): return arrayValue
    }
  }

  public init(stringLiteral value: String) {
    self = .string(value)
  }

  public init(unicodeScalarLiteral value: String) {
    self = .string(value)
  }

  public init(extendedGraphemeClusterLiteral value: String) {
    self = .string(value)
  }

  public init(integerLiteral value: IntegerLiteralType) {
    self = .int(value)
  }

  public init(booleanLiteral value: BooleanLiteralType) {
    self = .bool(value)
  }

  public init(floatLiteral value: FloatLiteralType) {
    self = .float(Float(value))
  }

  public init(arrayLiteral elements: ArrayLiteralElement...) {
    self = .array(elements)
  }
}

public typealias Properties = Dictionary<String, PropertyValue>

extension Properties {
  func asMessage() -> Common_Properties {
    
  }
}

@objc(PROProperties) @objcMembers
public class _ObjCProperties: NSObject {

  private(set) var properties: Properties

  public override init() {
    self.properties = Properties()
    super.init()
  }

  public subscript(key: String) -> NSObject? {
    guard let value = properties[key] else { return nil }
    switch value.rawValue {
    case let intValue as Int:
      return NSNumber(value: intValue)
    case let stringValue as String:
      return NSString(string: stringValue)
    case let boolValue as Bool:
      return NSNumber(value: boolValue)
    case let floatValue as Float:
      return NSNumber(value: floatValue)
    case let arrayValue as Array<PropertyValue>:
      return NSArray(array: arrayValue)
    default: return nil
    }
  }

  public func intValueForKey(_ key: String) -> Int? {
    return properties[key]?.rawValue as? Int
  }

  public func stringValueForKey(_ key: String) -> String? {
    return properties[key]?.rawValue as? String
  }

  public func boolValueForKey(_ key: String) -> Bool? {
    return properties[key]?.rawValue as? Bool
  }

  public func floatValueForKey(_ key: String) -> Float? {
    return properties[key]?.rawValue as? Float
  }

  public func arrayValueForKey(_ key: String) -> Array<PropertyValue>? {
    return properties[key]?.rawValue as? Array<PropertyValue>
  }

  public func setIntValue(_ value: Int?, forKey key: String) {
    properties[key] = .value(for: value)
  }

  public func setStringValue(_ value: String?, forKey key: String) {
    properties[key] = .value(for: value)
  }

  public func setBoolValue(_ value: Bool?, forKey key: String) {
    properties[key] = .value(for: value)
  }

  public func setFloatValue(_ value: Float?, forKey key: String) {
    properties[key] = .value(for: value)
  }

  public func setArrayValue(_ value: Array<PropertyValue>?, forKey key: String) {
    properties[key] = .value(for: value)
  }
}

import Foundation

/** Type for origin of impressed content. */
@objc(PROImpressionSourceType)
public enum ImpressionSourceType: Int {
  case unknown = 0

  /// Promoted Delivery API.
  case delivery = 1

  /// Non-Promoted backend.
  case clientBackend = 2
}

extension ImpressionSourceType: RawRepresentable {
  public init?(rawValue: Int) {
    switch rawValue {
    case 0: self = .unknown
    case 1: self = .delivery
    case 2: self = .clientBackend
    default: self = .unknown
    }
  }
}

extension ImpressionSourceType: CustomStringConvertible {
  public var description: String {
    switch self {
    case .unknown: return "unknown"
    case .delivery: return "delivery"
    case .clientBackend: return "clientBackend"
    default: return "unknown"
    }
  }
}

extension ImpressionSourceType {
  var protoValue: Event_ImpressionSourceType {
    Event_ImpressionSourceType(rawValue: self.rawValue) ??
      .unknownImpressionSourceType
  }
}

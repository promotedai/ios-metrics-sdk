import Foundation

/** Currency codes. Wraps `Common_CurrencyCode`. */
@objc(PROCurrencyCode)
public enum CurrencyCode: Int {
  case unknown // = 0
  case USD // = 1
  case EUR // = 2
  case JPY // = 3
  case GBP // = 4
  case AUD // = 5
  case CAD // = 6
  case CHF // = 7
  case CNY // = 8
  case HKD // = 9
  case NZD // = 10
  case SEK // = 11
  case KRW // = 12
  case SGD // = 13
  case NOK // = 14
  case MXN // = 15
  case INR // = 16
  case RUB // = 17
  case ZAR // = 18
  case TRY // = 19
  case BRL // = 20
}

extension CurrencyCode: RawRepresentable {
  public init?(rawValue: Int) {
    switch rawValue {
    case 0: self = .unknown
    case 1: self = .USD
    case 2: self = .EUR
    case 3: self = .JPY
    case 4: self = .GBP
    case 5: self = .AUD
    case 6: self = .CAD
    case 7: self = .CHF
    case 8: self = .CNY
    case 9: self = .HKD
    case 10: self = .NZD
    case 11: self = .SEK
    case 12: self = .KRW
    case 13: self = .SGD
    case 14: self = .NOK
    case 15: self = .MXN
    case 16: self = .INR
    case 17: self = .RUB
    case 18: self = .ZAR
    case 19: self = .TRY
    case 20: self = .BRL
    default: self = .unknown
    }
  }

  public var rawValue: Int {
    switch self {
    case .unknown: return 0
    case .USD: return 1
    case .EUR: return 2
    case .JPY: return 3
    case .GBP: return 4
    case .AUD: return 5
    case .CAD: return 6
    case .CHF: return 7
    case .CNY: return 8
    case .HKD: return 9
    case .NZD: return 10
    case .SEK: return 11
    case .KRW: return 12
    case .SGD: return 13
    case .NOK: return 14
    case .MXN: return 15
    case .INR: return 16
    case .RUB: return 17
    case .ZAR: return 18
    case .TRY: return 19
    case .BRL: return 20
    default: return 0
    }
  }
}

extension CurrencyCode: CustomStringConvertible {
  public var description: String {
    switch self {
    case .unknown: return "unknown"
    case .USD: return "USD"
    case .EUR: return "EUR"
    case .JPY: return "JPY"
    case .GBP: return "GBP"
    case .AUD: return "AUD"
    case .CAD: return "CAD"
    case .CHF: return "CHF"
    case .CNY: return "CNY"
    case .HKD: return "HKD"
    case .NZD: return "NZD"
    case .SEK: return "SEK"
    case .KRW: return "KRW"
    case .SGD: return "SGD"
    case .NOK: return "NOK"
    case .MXN: return "MXN"
    case .INR: return "INR"
    case .RUB: return "RUB"
    case .ZAR: return "ZAR"
    case .TRY: return "TRY"
    case .BRL: return "BRL"
    default: return "unknown"
    }
  }
}

extension CurrencyCode {
  var protoValue: Common_CurrencyCode {
    Common_CurrencyCode(rawValue: self.rawValue) ?? .unknownCurrencyCode
  }
}

import Foundation

/** Money amount for transactions. Wraps `Common_Money`. */
@objc(PROMoney) @objcMembers
public class Money: NSObject {

  public var currencyCode: CurrencyCode

  public var amountMicros: Int64

  public override convenience init() {
    self.init(currencyCode: .unknown, amountMicros: 0)
  }

  public init(currencyCode: CurrencyCode, amountMicros: Int64) {
    self.currencyCode = currencyCode
    self.amountMicros = amountMicros
  }
}

public extension Money {
  override var description: String { debugDescription }

  override var debugDescription: String {
    return "(currencyCode=\(currencyCode), amountMicros=\(amountMicros))"
  }

  override func isEqual(_ object: Any?) -> Bool {
    if let other = object as? Money {
      return (
        self.currencyCode == other.currencyCode &&
        self.amountMicros == other.amountMicros
      )
    }
    return false
  }

  override var hash: Int {
    var hasher = Hasher()
    hasher.combine(currencyCode)
    hasher.combine(amountMicros)
    return hasher.finalize()
  }
}

extension Money: MessageRepresentable {
  public func asMessage() -> Common_Money {
    var result = Common_Money()
    result.currencyCode = currencyCode.protoValue
    result.amountMicros = amountMicros
    return result
  }
}

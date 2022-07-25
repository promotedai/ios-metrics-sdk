import Foundation

/** Money amount for transactions. Wraps `Common_Money`. */
@objc(PROMoney)
public class Money: NSObject {

  @objc public var currencyCode: CurrencyCode

  @objc public var amountMicros: Int64

  @objc public override convenience init() {
    self.init(currencyCode: .unknown, amountMicros: 0)
  }

  @objc public init(currencyCode: CurrencyCode, amountMicros: Int64) {
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

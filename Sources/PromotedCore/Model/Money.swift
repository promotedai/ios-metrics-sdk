import Foundation

@objc(PROMoney)
public class Money: NSObject {

  @objc public var currencyCode: CurrencyCode

  @objc public var amountMicros: Int64
}

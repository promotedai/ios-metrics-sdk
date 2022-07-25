import Foundation

@objc(PROCartContent)
public class CartContent: NSObject {

  @objc public var content: Content

  @objc public var quantity: Int

  @objc public var pricePerUnit: Money?
}

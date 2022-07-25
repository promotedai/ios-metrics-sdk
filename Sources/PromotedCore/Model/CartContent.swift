import Foundation

/** Item of content in a shopping cart. Wraps `Event_CartContent`. */
@objc(PROCartContent)
public class CartContent: NSObject {

  @objc public var content: Content

  @objc public var quantity: Int

  @objc public var pricePerUnit: Money?

  @objc public override convenience init() {
    self.init(content: Content(), quantity: 1, pricePerUnit: nil)
  }

  @objc public init(content: Content, quantity: Int, pricePerUnit: Money?) {
    self.content = content
    self.quantity = quantity
    self.pricePerUnit = pricePerUnit
  }
}

public extension CartContent {
  override var description: String { debugDescription }

  override var debugDescription: String {
    return (
      "(content=\(content), " +
      "quantity=\(quantity)" +
      "\(pricePerUnit != nil ? ", \(pricePerUnit!)" : "")"
    )
  }

  override func isEqual(_ object: Any?) -> Bool {
    if let other = object as? CartContent {
      return (
        self.content == other.content &&
        self.quantity == other.quantity &&
        self.pricePerUnit == other.pricePerUnit
      )
    }
    return false
  }

  override var hash: Int {
    var hasher = Hasher()
    hasher.combine(content)
    hasher.combine(quantity)
    hasher.combine(pricePerUnit)
    return hasher.finalize()
  }
}

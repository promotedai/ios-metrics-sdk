import Foundation

/** Item of content in a shopping cart. Wraps `Event_CartContent`. */
@objc(PROCartContent) @objcMembers
public class CartContent: NSObject {

  public var content: Content

  public var quantity: Int

  public var pricePerUnit: Money?

  public override convenience init() {
    self.init(content: Content(), quantity: 1, pricePerUnit: nil)
  }

  public init(content: Content, quantity: Int, pricePerUnit: Money?) {
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

extension CartContent: MessageRepresentable {
  public func asMessage() -> Event_CartContent {
    var result = Event_CartContent()
    if let c = content.contentID { result.contentID = c }
    // if let i = content.insertionID { result.insertionID = i }
    result.quantity = Int64(quantity)
    if let price = pricePerUnit {
      result.pricePerUnit = price.asMessage()
    }
    return result
  }
}

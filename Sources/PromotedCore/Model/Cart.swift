import Foundation

/** Shopping cart for `checkout` or `purchase` actions. Wraps `Event_Cart`. */
@objc(PROCart)
public class Cart: NSObject {

  @objc public var contents: [CartContent]

  @objc public override convenience init() {
    self.init(contents: [])
  }

  @objc public init(contents: [CartContent]) {
    self.contents = contents
  }
}

public extension Cart {
  override var description: String { debugDescription }

  override var debugDescription: String {
    return "(contents=\(contents)"
  }

  override func isEqual(_ object: Any?) -> Bool {
    if let other = object as? Cart {
      return self.contents == other.contents
    }
    return false
  }

  override var hash: Int { contents.hashValue }
}

extension Cart: MessageRepresentable {
  public func asMessage() -> Event_Cart {
    var result = Event_Cart()
    result.contents = contents.map { $0.asMessage() }
    return result
  }
}

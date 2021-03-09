import Foundation

/**
 Represents a saleable unit in your marketplace.
 */
@objc(PROItem)
public class Item: NSObject {

  /// Unique ID for this item. Can be an internal ID from your system.
  @objc public var itemID: String?

  /// Insertion ID as generated by Promoted.
  @objc public var insertionID: String?
  
  /// Initializes with nil `itemID` and nil `insertionID`.
  @objc public override init() {
    self.itemID = nil
    self.insertionID = nil
  }
  
  /// Initializes with the given `itemID` and nil `insertionID`.
  @objc public init(itemID: String) {
    self.itemID = itemID
    self.insertionID = nil
  }
  
  /// Initializes with the given `itemID = wardrobeID` and reads remaining
  /// attributes from `dictionary`.
  @objc public init(itemID: String, insertionID: String) {
    self.itemID = itemID
    self.insertionID = insertionID
  }
}

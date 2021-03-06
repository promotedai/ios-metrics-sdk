import Foundation

/**
 Represents a saleable unit in your marketplace.
 */
@objc public protocol Item {

  /// Unique ID for this item. Can be an internal ID from your system.
  @objc var itemID: String? { get }

  /// Insertion ID as generated by Promoted.
  @objc var insertionID: String? { get }
}
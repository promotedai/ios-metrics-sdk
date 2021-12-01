import Foundation

/**
 Client-side data from a user interaction with collection view.
 */
public struct CollectionInteraction {

  /// For interactions involving collections, this is the
  /// index path of the cell involved in the interaction.
  public let indexPath: [Int32]

  public init<C: Collection, E: BinaryInteger>(
    indexPath: C
  ) where C.Element == E {
    self.indexPath = indexPath.map { Int32(truncatingIfNeeded: $0) }
  }
}

extension CollectionInteraction: CustomStringConvertible {
  public var description: String { debugDescription }
}

extension CollectionInteraction: CustomDebugStringConvertible {
  public var debugDescription: String {
    "(indexPath: \(indexPath))"
  }
}

extension CollectionInteraction: Hashable {
  public func hash(into hasher: inout Hasher) {
    hasher.combine(indexPath)
  }

  public static func == (
    lhs: CollectionInteraction,
    rhs: CollectionInteraction
  ) -> Bool {
    lhs.indexPath == rhs.indexPath
  }
}

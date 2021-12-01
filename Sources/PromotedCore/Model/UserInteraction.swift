import Foundation

/**
 Client-side data from a user interaction.
 */
public struct UserInteraction {

  /// For interactions involving collections, this is the
  /// index path of the cell involved in the interaction.
  public let indexPath: [Int32]

  public init<C: Collection, E: BinaryInteger>(
    indexPath: C
  ) where C.Element == E {
    self.indexPath = indexPath.map { Int32(truncatingIfNeeded: $0) }
  }
}

extension UserInteraction: CustomStringConvertible {
  public var description: String { debugDescription }
}

extension UserInteraction: CustomDebugStringConvertible {
  public var debugDescription: String {
    "(indexPath: \(indexPath))"
  }
}

extension UserInteraction: Hashable {
  public func hash(into hasher: inout Hasher) {
    hasher.combine(indexPath)
  }

  public static func == (
    lhs: UserInteraction,
    rhs: UserInteraction
  ) -> Bool {
    lhs.indexPath == rhs.indexPath
  }
}

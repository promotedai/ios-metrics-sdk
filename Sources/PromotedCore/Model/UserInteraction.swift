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
    self.indexPath = indexPath.map { Int32(truncatingIfNeeded: $0 ) }
  }
}

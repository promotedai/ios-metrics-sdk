import Foundation

/**
 Convenience protocol to interoperate with `UICollectionView` and other
 UIKit classes that use `IndexPath`s.
 */
@objc(PROIndexPathDataSource)
public protocol IndexPathDataSource {

  /// Returns content for given index path.
  /// If `nil`, does not log given content.
  @objc func contentFor(indexPath: IndexPath) -> Content?
}

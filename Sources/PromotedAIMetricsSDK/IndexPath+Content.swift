import Foundation

/**
 Convenience methods to interoperate with sectioned content arrays.
 Avoids UIKit dependency so we can unit test on macOS.
 */
extension IndexPath {

  var contentSection: Int {
    return count > 1 ? self[0] : 0
  }

  var contentItem: Int {
    return count > 1 ? self[1] : self[0]
  }

  func valueFromArray<T>(_ array: [[T]]) -> T? {
    let section = contentSection
    guard section < array.count else { return nil }
    let item = contentItem
    guard item < array[section].count else { return nil }
    return array[section][item]
  }

  func setValue<T>(_ value: T, inArray array: inout [[T]]) {
    let section = contentSection
    guard section < array.count else { return }
    let item = contentItem
    guard item < array[section].count else { return }
    array[section][item] = value
  }
}

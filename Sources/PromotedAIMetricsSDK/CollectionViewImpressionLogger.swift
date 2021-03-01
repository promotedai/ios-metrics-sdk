import Foundation
#if canImport(UIKit)
import UIKit
#endif

@objc(PROCollectionViewCellImpression)
public class CollectionViewCellImpression: NSObject {
  @objc public var path: IndexPath
  @objc public var startTime: TimeInterval
  @objc public var endTime: TimeInterval

  @objc public var duration: TimeInterval {
    get {
      if endTime < 0.0 { return -1.0 }
      return endTime - startTime
    }
  }

  public init(path: IndexPath, startTime: TimeInterval, endTime: TimeInterval = -1.0) {
    self.path = path
    self.startTime = startTime
    self.endTime = endTime
  }

  public override var debugDescription: String {
    return "(\(path.description), \(startTime), \(endTime))"
  }
  
  public override var hash: Int {
    return path.hashValue
  }

  public override func isEqual(_ object: Any?) -> Bool {
    guard let rhs = object as? CollectionViewCellImpression else { return false }
    return self == rhs
  }
  
  static func == (lhs: CollectionViewCellImpression, rhs: CollectionViewCellImpression) -> Bool {
    if lhs === rhs { return true }
    return ((lhs.path == rhs.path) && (abs(lhs.startTime - rhs.startTime) < 0.01) &&
            (abs(lhs.endTime - rhs.endTime) < 0.01))
  }
}

@objc(PROCollectionViewImpressionLoggerDelegate)
public protocol CollectionViewImpressionLoggerDelegate {
  func impressionLogger(
      _ impressionLogger: CollectionViewImpressionLogger,
      didStartImpressions impressions: [CollectionViewCellImpression])
  func impressionLogger(
      _ impressionLogger: CollectionViewImpressionLogger,
      didEndImpressions impressions: [CollectionViewCellImpression])
}

@objc(PROCollectionViewImpressionLoggerDataSource)
public protocol CollectionViewImpressionLoggerDataSource {
  var indexPathsForVisibleItems: [IndexPath] { get }
}

#if canImport(UIKit)
class UICollectionViewDataSource : CollectionViewImpressionLoggerDataSource {
  private var collectionView: UICollectionView
  init(_ collectionView: UICollectionView) {
    self.collectionView = collectionView
  }
  var indexPathsForVisibleItems: [IndexPath] {
    return collectionView.indexPathsForVisibleItems
  }
}
#endif

@objc(PROCollectionViewImpressionLogger)
public class CollectionViewImpressionLogger: NSObject {
  private let dataSource: CollectionViewImpressionLoggerDataSource
  private let clock: Clock
  private var impressionStarts: [IndexPath: TimeInterval]

  public weak var delegate: CollectionViewImpressionLoggerDelegate?

  #if canImport(UIKit)
  @objc public convenience init(
      collectionView: UICollectionView,
      delegate: CollectionViewImpressionLoggerDelegate? = nil) {
    self.init(dataSource: UICollectionViewDataSource(collectionView),
              delegate: delegate)
  }
  #endif

  public init(
      dataSource: CollectionViewImpressionLoggerDataSource,
      delegate: CollectionViewImpressionLoggerDelegate? = nil,
      clock: Clock = SystemClock()) {
    self.dataSource = dataSource
    self.clock = clock
    self.impressionStarts = [IndexPath: TimeInterval]()
    self.delegate = delegate
  }

  @objc(collectionViewWillDisplayItem:)
  public func collectionViewWillDisplay(item: IndexPath) {
    broadcastStartAndAddImpressions(items: [item], now: clock.now)
  }

  @objc(collectionViewDidHideItem:)
  public func collectionViewDidHide(item: IndexPath) {
    broadcastEndAndRemoveImpressions(items: [item], now: clock.now)
  }

  @objc public func collectionViewDidReloadAllItems() {
    let now = clock.now
    let visibleItems = dataSource.indexPathsForVisibleItems

    var newlyShownItems = [IndexPath]()
    for item in visibleItems {
      if impressionStarts[item] == nil {
        newlyShownItems.append(item)
      }
    }

    var newlyHiddenItems = [IndexPath]()
    for item in impressionStarts.keys {
      if !visibleItems.contains(item) {
        newlyHiddenItems.append(item)
      }
    }

    broadcastStartAndAddImpressions(items: newlyShownItems, now: now)
    broadcastEndAndRemoveImpressions(items: newlyHiddenItems, now: now)
  }

  @objc public func collectionViewDidHideAllItems() {
    let keys = [IndexPath](impressionStarts.keys)
    broadcastEndAndRemoveImpressions(items: keys, now: clock.now)
  }
  
  private func broadcastStartAndAddImpressions(items: [IndexPath], now: TimeInterval) {
    guard !items.isEmpty else { return }
    var impressions = [CollectionViewCellImpression]()
    for item in items {
      let impression = CollectionViewCellImpression(path: item, startTime: now)
      impressions.append(impression)
      impressionStarts[item] = now
    }
    if let delegate = self.delegate {
      delegate.impressionLogger(self, didStartImpressions: impressions)
    }
  }
  
  private func broadcastEndAndRemoveImpressions(items: [IndexPath], now: TimeInterval) {
    guard !items.isEmpty else { return }
    var impressions = [CollectionViewCellImpression]()
    for item in items {
      guard let start = impressionStarts.removeValue(forKey: item)
          else { continue }
      let impression = CollectionViewCellImpression(path: item, startTime: start, endTime: now)
      impressions.append(impression)
    }
    if let delegate = self.delegate {
      delegate.impressionLogger(self, didEndImpressions: impressions)
    }
  }
}

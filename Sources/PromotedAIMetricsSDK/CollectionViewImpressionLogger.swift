import Foundation
import UIKit

@objc(PACollectionViewCellImpression)
public class CollectionViewCellImpression: NSObject {
  @objc public var path: IndexPath
  @objc public var duration: TimeInterval
  public init(path: IndexPath, duration: TimeInterval) {
    self.path = path
    self.duration = duration
  }
}

@objc(PACollectionViewImpressionLoggerDelegate)
public protocol CollectionViewImpressionLoggerDelegate {
  func impressionLogger(_ impressionLogger: CollectionViewImpressionLogger, didRecordImpressions impressions: [CollectionViewCellImpression])
}

@objc(PACollectionViewImpressionLoggerDataSource)
public protocol CollectionViewImpressionLoggerDataSource {
  var indexPathsForVisibleItems: [IndexPath] { get }
}

class UICollectionViewDataSource : CollectionViewImpressionLoggerDataSource {
  private var collectionView: UICollectionView
  init(_ collectionView: UICollectionView) {
    self.collectionView = collectionView
  }
  var indexPathsForVisibleItems: [IndexPath] {
    return collectionView.indexPathsForVisibleItems
  }
}

@objc(PACollectionViewImpressionLogger)
public class CollectionViewImpressionLogger: NSObject {
  private var dataSource: CollectionViewImpressionLoggerDataSource
  private var impressionStarts: [IndexPath: TimeInterval]
  public weak var delegate: CollectionViewImpressionLoggerDelegate?
  @objc public convenience init(collectionView: UICollectionView, delegate: CollectionViewImpressionLoggerDelegate? = nil) {
    self.init(dataSource: UICollectionViewDataSource(collectionView), delegate: delegate)
  }
  public init(dataSource: CollectionViewImpressionLoggerDataSource,
        delegate: CollectionViewImpressionLoggerDelegate? = nil) {
    self.dataSource = dataSource
    self.impressionStarts = [IndexPath: TimeInterval]()
    self.delegate = delegate
  }
  @objc public func collectionViewWillDisplay(item: IndexPath) {
    let now = Date().timeIntervalSince1970
    impressionStarts[item] = now
  }
  @objc public func collectionViewDidHide(item: IndexPath) {
    broadcastAndRemoveImpressions(items: [item])
  }
  @objc public func collectionViewDidReloadAllItems() {
    let now = Date().timeIntervalSince1970
    let visibleItems = dataSource.indexPathsForVisibleItems
    var newlyShownItems = Set<IndexPath>()
    for item in visibleItems {
      if impressionStarts[item] == nil {
        newlyShownItems.insert(item)
      }
    }
    var newlyHiddenItems = Set<IndexPath>()
    for item in impressionStarts.keys {
      if !visibleItems.contains(item) {
        newlyHiddenItems.insert(item)
      }
    }
    for item in newlyShownItems {
      impressionStarts[item] = now
    }
    if newlyHiddenItems.isEmpty {
      return
    }
    broadcastAndRemoveImpressions(items: newlyHiddenItems, now: now)
  }
  @objc public func collectionViewDidHideAllItems() {
    let keys = [IndexPath](impressionStarts.keys)
    broadcastAndRemoveImpressions(items: keys)
  }
  private func broadcastAndRemoveImpressions<S>(items: S, now: TimeInterval = Date().timeIntervalSince1970) where S: Sequence, S.Element == IndexPath {
    if let delegate = self.delegate {
      var impressions = [CollectionViewCellImpression]()
      for item in items {
        guard let start = impressionStarts.removeValue(forKey: item) else { continue }
        let duration = now - start
        let impression = CollectionViewCellImpression(path: item, duration: duration)
        impressions.append(impression)
      }
      delegate.impressionLogger(self, didRecordImpressions: impressions)
    }
  }
}

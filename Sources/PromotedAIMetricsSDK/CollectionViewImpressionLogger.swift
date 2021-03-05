import Foundation

// MARK: -
/** Represents an impression of a cell in the collection view. */
@objc(PROCollectionViewCellImpression)
public class CollectionViewCellImpression: NSObject {
  
  /// Index path of the cell that was impressed.
  @objc public var path: IndexPath
  
  /// Start time of impression.
  @objc public var startTime: TimeInterval
  
  /// End time of impression, if available. If not, returns -1.
  @objc public var endTime: TimeInterval

  /// Duration of impression, if available. If not, returns -1.
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
  
  static func == (lhs: CollectionViewCellImpression,
                  rhs: CollectionViewCellImpression) -> Bool {
    if lhs === rhs { return true }
    return ((lhs.path == rhs.path) && (abs(lhs.startTime - rhs.startTime) < 0.01) &&
            (abs(lhs.endTime - rhs.endTime) < 0.01))
  }
}

// MARK: -
/** Delegate to be notified when impressions start or end. */
@objc(PROCollectionViewImpressionLoggerDelegate)
public protocol CollectionViewImpressionLoggerDelegate {

  /// Notifies delegate of impression starts.
  func impressionLogger(
      _ impressionLogger: CollectionViewImpressionLogger,
      didStartImpressions impressions: [CollectionViewCellImpression])
  
  /// Notifies delegate of impression ends.
  func impressionLogger(
      _ impressionLogger: CollectionViewImpressionLogger,
      didEndImpressions impressions: [CollectionViewCellImpression])
}

// MARK: -
/**
 Tracks impressions across scrolling collection views, such as
 `UICollectionView` or `UITableView`. Works best with views that
 can provide fine-grained updates of visible cells, but can also
 be adapted to work with views that don't.
 
 Clients should create an instance of `CollectionViewImpressionLogger`
 and reference it in their view controller, then provide updates
 to the impression logger as the collection view scrolls or updates.
 
 # Example:
 ~~~
 @implementation MyViewController {
   UICollectionView *_collectionView;
   PROCollectionViewImpressionLogger *_impressionLogger;
 }

 - (void)viewWillDisappear:(BOOL)animated {
   [_impressionLogger collectionViewDidHideAllItems];
 }

 - (void)collectionView:(UICollectionView *)collectionView
        willDisplayCell:(UICollectionViewCell *)cell
     forItemAtIndexPath:(NSIndexPath *)indexPath {
   [_impressionLogger collectionViewWillDisplayItem:indexPath];
 }
  
 - (void)collectionView:(UICollectionView *)collectionView
   didEndDisplayingCell:(UICollectionViewCell *)cell
     forItemAtIndexPath:(NSIndexPath *)indexPath {
   [_impressionLogger collectionViewDidHideItem:indexPath];
 }

 - (void)reloadCollectionView {
   [_collectionView reloadData];
   NSArray<NSIndexPath *> *items =
       _collectionView.indexPathsForVisibleItems;
   [_impressionLogger collectionViewDidReloadWithVisibleItems:items];
 }
 ~~~
 */
@objc(PROCollectionViewImpressionLogger)
open class CollectionViewImpressionLogger: NSObject {
  private let clock: Clock
  private var impressionStarts: [IndexPath: TimeInterval]

  public weak var delegate: CollectionViewImpressionLoggerDelegate?

  public init(delegate: CollectionViewImpressionLoggerDelegate? = nil,
              clock: Clock) {
    self.clock = clock
    self.impressionStarts = [IndexPath: TimeInterval]()
    self.delegate = delegate
  }

  /// Call this method when new items are displayed.
  @objc(collectionViewWillDisplayItem:)
  public func collectionViewWillDisplay(item: IndexPath) {
    broadcastStartAndAddImpressions(items: [item], now: clock.now)
  }

  /// Call this method when previously displayed items are hidden.
  /// If an item is reported as hidden that had not previously
  /// been displayed, the impression for that item will be ignored.
  @objc(collectionViewDidHideItem:)
  public func collectionViewDidHide(item: IndexPath) {
    broadcastEndAndRemoveImpressions(items: [item], now: clock.now)
  }

  /// Call this method when the collection view changes content, but
  /// does not provide per-item updates for the change. For example,
  /// when a collection reloads.
  @objc public func collectionViewDidReload(visibleItems: [IndexPath]) {
    let now = clock.now

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

  /// Call this method when the collection view hides.
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
    delegate?.impressionLogger(self, didStartImpressions: impressions)
  }
  
  private func broadcastEndAndRemoveImpressions(items: [IndexPath], now: TimeInterval) {
    guard !items.isEmpty else { return }
    var impressions = [CollectionViewCellImpression]()
    for item in items {
      guard let start = impressionStarts.removeValue(forKey: item) else { continue }
      let impression = CollectionViewCellImpression(path: item, startTime: start, endTime: now)
      impressions.append(impression)
    }
    delegate?.impressionLogger(self, didEndImpressions: impressions)
  }
}

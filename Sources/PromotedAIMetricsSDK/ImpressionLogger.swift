import Foundation

// MARK: -
/** Delegate to be notified when impressions start or end. */
public protocol ImpressionLoggerDelegate: class {

  /// Notifies delegate of impression starts.
  func impressionLogger(
      _ impressionLogger: ImpressionLogger,
      didStartImpressions impressions: [ImpressionLogger.Impression])
  
  /// Notifies delegate of impression ends.
  func impressionLogger(
      _ impressionLogger: ImpressionLogger,
      didEndImpressions impressions: [ImpressionLogger.Impression])
}

// MARK: -
/**
 Provides `Item`s displayed in a collection view.
 Typically, a `UIViewController` that hosts the collection view
 will implement this protocol.
 
 # Example:
 ~~~
 @interface MyViewController () <PROQueenlyWardrobeItemDataSource>
 @end
 
 @implementation MyViewController
 
 - (void)createImpressionLogger {
   _logger = [_service impressionLoggerWithDataSource:self];
 }
 
 - (PROItem *)impressionLoggerItemAt:(NSIndexPath *)indexPath {
   NSInteger item = indexPath.item;
   if (item >= _items.count) { return nil; }
   NSDictionary<NSString *, NSString *> *item = _items[item];
   return [[PROItem alloc] initWithDictionary:item];
 }
 
 @end
 ~~~
 */
@objc(PROImpressionLoggerDataSource)
public protocol ImpressionLoggerDataSource {
  
  /// Returns the item at the given index path. Return `nil` if no
  /// such item exists.
  /// **IMPORTANT**: Always check the range of the index path, in case
  /// your collection view displays cells at index paths that are not
  /// wardrobe items.
  @objc func impressionLoggerItem(at indexPath: IndexPath) -> Item?
}

// MARK: -
/**
 Tracks impressions across scrolling collection views, such as
 `UICollectionView` or `UITableView`. Works best with views that
 can provide fine-grained updates of visible cells, but can also
 be adapted to work with views that don't.
 
 Clients should create an instance of `ImpressionLogger`
 and reference it in their view controller, then provide updates
 to the impression logger as the collection view scrolls or updates.
 
 # Example:
 ~~~
 @implementation MyViewController {
   UICollectionView *_collectionView;
   PROImpressionLogger *_impressionLogger;
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
@objc(PROImpressionLogger)
public class ImpressionLogger: NSObject {

  // MARK: -
  /** Represents an impression of a cell in the collection view. */
  public struct Impression: CustomDebugStringConvertible, Hashable {
   
    /// Index path of the cell that was impressed.
    public var path: IndexPath
    
    /// Start time of impression.
    public var startTime: TimeInterval
    
    /// End time of impression, if available. If not, returns -1.
    public var endTime: TimeInterval

    /// Duration of impression, if available. If not, returns -1.
    public var duration: TimeInterval {
      get {
        if endTime < 0.0 { return -1.0 }
        return endTime - startTime
      }
    }

    public init(path: IndexPath,
                startTime: TimeInterval,
                endTime: TimeInterval = -1.0) {
      self.path = path
      self.startTime = startTime
      self.endTime = endTime
    }

    public var debugDescription: String {
      return "(\(path.description), \(startTime), \(endTime))"
    }
    
    public func hash(into hasher: inout Hasher) {
      hasher.combine(path)
    }
    
    public static func == (lhs: ImpressionLogger.Impression,
                           rhs: ImpressionLogger.Impression) -> Bool {
      return ((lhs.path == rhs.path) && (abs(lhs.startTime - rhs.startTime) < 0.01) &&
              (abs(lhs.endTime - rhs.endTime) < 0.01))
    }
  }
  
  // MARK: -
  private class ArrayDataSource: ImpressionLoggerDataSource {
    private let array: [Item]
    init(array: [Item]) { self.array = array }
    func impressionLoggerItem(at indexPath: IndexPath) -> Item? {
      guard let index = indexPath.first else { return nil }
      if index < array.count { return array[index] }
      return nil
    }
  }

  // MARK: -
  private let arrayDataSource: ArrayDataSource?
  private weak var dataSource: ImpressionLoggerDataSource?
  private weak var metricsLogger: MetricsLogger?
  private let clock: Clock
  private var impressionStarts: [IndexPath: TimeInterval]

  public weak var delegate: ImpressionLoggerDelegate?

  init(dataSource: ImpressionLoggerDataSource,
       metricsLogger: MetricsLogger,
       clock: Clock) {
    self.arrayDataSource = nil
    self.dataSource = dataSource
    self.metricsLogger = metricsLogger
    self.clock = clock
    self.impressionStarts = [IndexPath: TimeInterval]()
  }
  
  init(array: [Item],
       metricsLogger: MetricsLogger,
       clock: Clock) {
    self.arrayDataSource = ArrayDataSource(array: array)
    self.dataSource = self.arrayDataSource
    self.metricsLogger = metricsLogger
    self.clock = clock
    self.impressionStarts = [IndexPath: TimeInterval]()
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
  @objc public func collectionViewDidChange(visibleItems: [IndexPath]) {
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
    var impressions = [Impression]()
    for item in items {
      let impression = Impression(path: item, startTime: now)
      impressions.append(impression)
      impressionStarts[item] = now
    }
    for impression in impressions {
      if let item = dataSource?.impressionLoggerItem(at: impression.path) {
        metricsLogger?.logImpression(item: item)
      }
    }
    delegate?.impressionLogger(self, didStartImpressions: impressions)
  }
  
  private func broadcastEndAndRemoveImpressions(items: [IndexPath], now: TimeInterval) {
    guard !items.isEmpty else { return }
    var impressions = [Impression]()
    for item in items {
      guard let start = impressionStarts.removeValue(forKey: item) else { continue }
      let impression = Impression(path: item, startTime: start, endTime: now)
      impressions.append(impression)
    }
    // Not calling `metricsLogger`. No logging end impressions for now.
    delegate?.impressionLogger(self, didEndImpressions: impressions)
  }
}

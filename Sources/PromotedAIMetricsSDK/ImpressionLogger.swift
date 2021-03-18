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
 Provides `Content` displayed in a collection view.
 Typically, a `UIViewController` that hosts the collection view
 will implement this protocol.
 
 # Example:
 ~~~
 class MyViewController: ImpressionLoggerDataSource {
   func createImpressionLogger() {
     self.logger = service.impressionLogger(dataSource: self)
   }
   func impressionLoggerContent(at path: IndexPath) -> Content? {
     let item = path.item
     if item >= self.items.count { return nil }
     let myItemProperties = self.items[item]
     return Item(properties: myItemProperties)
   }
 }
 ~~~
 */
@objc(PROImpressionLoggerDataSource)
public protocol ImpressionLoggerDataSource {
  
  /// Returns the item at the given index path. Return `nil` if no
  /// such item exists.
  /// **IMPORTANT**: Always check the range of the index path, in case
  /// your collection view displays cells at index paths that are not
  /// wardrobe items.
  @objc func impressionLoggerContent(at indexPath: IndexPath) -> Content?
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
 class MyViewController: UIViewController {
   var collectionView: UICollectionView
   var logger: MetricsLogger
   var impressionLogger: ImpressionLogger

   func viewWillDisappear(_ animated: Bool) {
     impressionLogger.collectionViewDidHideAllItems()
   }

   func collectionView(_ collectionView: UICollectionView,
                       willDisplay cell: UICollectionViewCell,
                       forItemAt indexPath: IndexPath) {
     impressionLogger.collectionViewWillDisplayContent(atIndex: indexPath)
   }
    
   func collectionView(_ collectionView: UICollectionView,
                       didEndDisplaying cell: UICollectionViewCell,
                       forItemAt indexPath: IndexPath) {
     impressionLogger.collectionViewDidHideContent(atIndex: indexPath)
   }

   func reloadCollectionView() {
     self.collectionView.reloadData()
     let visibleItems = collectionView.indexPathsForVisibleItems;
     impressionLogger.collectionViewDidChangeVisibleContentAtIndexes:visibleItems)
   }
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
      return ((lhs.path == rhs.path) &&
              (abs(lhs.startTime - rhs.startTime) < 0.01) &&
              (abs(lhs.endTime - rhs.endTime) < 0.01))
    }
  }
  
  // MARK: -
  /** Stores a copy of content in the logger itself. */
  private class ArrayDataSource: ImpressionLoggerDataSource {
    let array: [[Content]]
    init(array: [[Content]]) { self.array = array }
    func impressionLoggerContent(at indexPath: IndexPath) -> Content? {
      return indexPath.valueFromArray(array)
    }
  }

  // MARK: -
  private let arrayDataSource: ArrayDataSource?
  private unowned let dataSource: ImpressionLoggerDataSource
  private unowned let metricsLogger: MetricsLogger
  private let clock: Clock
  private var impressionStarts: [IndexPath: TimeInterval]

  public weak var delegate: ImpressionLoggerDelegate?

  init(dataSource: ImpressionLoggerDataSource,
       metricsLogger: MetricsLogger,
       clock: Clock) {
    self.arrayDataSource = (dataSource as? ArrayDataSource) ?? nil
    self.dataSource = dataSource
    self.metricsLogger = metricsLogger
    self.clock = clock
    self.impressionStarts = [IndexPath: TimeInterval]()
  }
  
  convenience init(sectionedContent: [[Content]],
                   metricsLogger: MetricsLogger,
                   clock: Clock) {
    let arrayDataSource = ArrayDataSource(array: sectionedContent)
    self.init(dataSource: arrayDataSource, metricsLogger: metricsLogger, clock: clock)
  }

  /// Call this method when new items are displayed.
  @objc(collectionViewWillDisplayContentAtIndex:)
  public func collectionViewWillDisplayContent(atIndex index: IndexPath) {
    broadcastStartAndAddImpressions(indexes: [index], now: clock.now)
  }

  /// Call this method when previously displayed items are hidden.
  /// If an item is reported as hidden that had not previously
  /// been displayed, the impression for that item will be ignored.
  @objc(collectionViewDidHideContentAtIndex:)
  public func collectionViewDidHideContent(atIndex index: IndexPath) {
    broadcastEndAndRemoveImpressions(indexes: [index], now: clock.now)
  }

  /// Call this method when the collection view changes content, but
  /// does not provide per-item updates for the change. For example,
  /// when a collection reloads.
  @objc(collectionViewDidChangeVisibleContentAtIndexes:)
  public func collectionViewDidChangeVisibleContent(atIndexes indexes: [IndexPath]) {
    let now = clock.now

    var newlyShownItems = [IndexPath]()
    for item in indexes {
      if impressionStarts[item] == nil {
        newlyShownItems.append(item)
      }
    }

    var newlyHiddenItems = [IndexPath]()
    for item in impressionStarts.keys {
      if !indexes.contains(item) {
        newlyHiddenItems.append(item)
      }
    }

    broadcastStartAndAddImpressions(indexes: newlyShownItems, now: now)
    broadcastEndAndRemoveImpressions(indexes: newlyHiddenItems, now: now)
  }

  /// Call this method when the collection view hides.
  @objc public func collectionViewDidHideAllContent() {
    let keys = [IndexPath](impressionStarts.keys)
    broadcastEndAndRemoveImpressions(indexes: keys, now: clock.now)
  }
  
  private func broadcastStartAndAddImpressions(indexes: [IndexPath], now: TimeInterval) {
    guard !indexes.isEmpty else { return }
    var impressions = [Impression]()
    for index in indexes {
      let impression = Impression(path: index, startTime: now)
      impressions.append(impression)
      impressionStarts[index] = now
    }
    for impression in impressions {
      if let content = dataSource.impressionLoggerContent(at: impression.path) {
        print("***** logging impression for \(content)")
        metricsLogger.logImpression(content: content)
      }
    }
    delegate?.impressionLogger(self, didStartImpressions: impressions)
  }
  
  private func broadcastEndAndRemoveImpressions(indexes: [IndexPath], now: TimeInterval) {
    guard !indexes.isEmpty else { return }
    var impressions = [Impression]()
    for index in indexes {
      guard let start = impressionStarts.removeValue(forKey: index) else { continue }
      let impression = Impression(path: index, startTime: start, endTime: now)
      impressions.append(impression)
    }
    // Not calling `metricsLogger`. No logging end impressions for now.
    delegate?.impressionLogger(self, didEndImpressions: impressions)
  }
}

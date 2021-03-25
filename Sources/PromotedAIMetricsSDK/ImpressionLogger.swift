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
 
   private func content(atIndexPath path: IndexPath) -> Content? {
     let item = path.item
     if item >= self.items.count { return nil }
     let myItemProperties = self.items[item]
     return Item(properties: myItemProperties)
   }

   func viewWillDisappear(_ animated: Bool) {
     impressionLogger.collectionViewDidHideAllContent()
   }

   func collectionView(_ collectionView: UICollectionView,
                       willDisplay cell: UICollectionViewCell,
                       forItemAt indexPath: IndexPath) {
     if let content = content(atIndexPath: indexPath) {
      impressionLogger.collectionViewWillDisplay(content: content)
     }
   }
    
   func collectionView(_ collectionView: UICollectionView,
                       didEndDisplaying cell: UICollectionViewCell,
                       forItemAt indexPath: IndexPath) {
     if let content = content(atIndexPath: indexPath) {
       impressionLogger.collectionViewDidHide(content: content)
     }
   }

   func reloadCollectionView() {
     self.collectionView.reloadData()
     let visibleContent = collectionView.indexPathsForVisibleItems.map {
       path in content(atIndexPath: path)
     };
     impressionLogger.collectionViewDidChangeVisibleContent(visibleContent)
   }
 }
 ~~~
 */
@objc(PROImpressionLogger)
public class ImpressionLogger: NSObject {

  // MARK: -
  /** Represents an impression of a cell in the collection view. */
  public struct Impression: CustomDebugStringConvertible, Hashable {
   
    /// Content that was impressed.
    public var content: Content
    
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

    public init(content: Content,
                startTime: TimeInterval,
                endTime: TimeInterval = -1.0) {
      self.content = content
      self.startTime = startTime
      self.endTime = endTime
    }

    public var debugDescription: String {
      return "(\(content.description), \(startTime), \(endTime))"
    }
    
    public func hash(into hasher: inout Hasher) {
      hasher.combine(content)
    }
    
    public static func == (lhs: ImpressionLogger.Impression,
                           rhs: ImpressionLogger.Impression) -> Bool {
      return ((lhs.content == rhs.content) &&
              (abs(lhs.startTime - rhs.startTime) < 0.01) &&
              (abs(lhs.endTime - rhs.endTime) < 0.01))
    }
  }
  
  // MARK: -
  private unowned let metricsLogger: MetricsLogger
  private let clock: Clock
  private var impressionStarts: [Content: TimeInterval]

  public weak var delegate: ImpressionLoggerDelegate?

  init(metricsLogger: MetricsLogger,
       clock: Clock) {
    self.metricsLogger = metricsLogger
    self.clock = clock
    self.impressionStarts = [Content: TimeInterval]()
  }

  /// Call this method when new items are displayed.
  @objc(collectionViewWillDisplayContentAtIndex:)
  public func collectionViewWillDisplay(content: Content) {
    broadcastStartAndAddImpressions(contentArray: [content], now: clock.now)
  }

  /// Call this method when previously displayed items are hidden.
  /// If an item is reported as hidden that had not previously
  /// been displayed, the impression for that item will be ignored.
  @objc(collectionViewDidHideContentAtIndex:)
  public func collectionViewDidHide(content: Content) {
    broadcastEndAndRemoveImpressions(contentArray: [content], now: clock.now)
  }

  /// Call this method when the collection view changes content, but
  /// does not provide per-item updates for the change. For example,
  /// when a collection reloads.
  @objc(collectionViewDidChangeVisibleContentAtIndexes:)
  public func collectionViewDidChangeVisibleContent(_ contentArray: [Content]) {
    let now = clock.now

    var newlyShownContent = [Content]()
    for content in contentArray {
      if impressionStarts[content] == nil {
        newlyShownContent.append(content)
      }
    }

    var newlyHiddenContent = [Content]()
    for content in impressionStarts.keys {
      if !contentArray.contains(content) {
        newlyHiddenContent.append(content)
      }
    }

    broadcastStartAndAddImpressions(contentArray: newlyShownContent, now: now)
    broadcastEndAndRemoveImpressions(contentArray: newlyHiddenContent, now: now)
  }

  /// Call this method when the collection view hides.
  @objc public func collectionViewDidHideAllContent() {
    let keys = [Content](impressionStarts.keys)
    broadcastEndAndRemoveImpressions(contentArray: keys, now: clock.now)
  }
  
  private func broadcastStartAndAddImpressions(contentArray: [Content], now: TimeInterval) {
    guard !contentArray.isEmpty else { return }
    var impressions = [Impression]()
    for content in contentArray {
      let impression = Impression(content: content, startTime: now)
      impressions.append(impression)
      impressionStarts[content] = now
    }
    for impression in impressions {
      print("***** Impression: \(impression.content)")
      metricsLogger.logImpression(content: impression.content)
    }
    delegate?.impressionLogger(self, didStartImpressions: impressions)
  }
  
  private func broadcastEndAndRemoveImpressions(contentArray: [Content], now: TimeInterval) {
    guard !contentArray.isEmpty else { return }
    var impressions = [Impression]()
    for content in contentArray {
      guard let start = impressionStarts.removeValue(forKey: content) else { continue }
      let impression = Impression(content: content, startTime: start, endTime: now)
      impressions.append(impression)
    }
    // Not calling `metricsLogger`. No logging end impressions for now.
    delegate?.impressionLogger(self, didEndImpressions: impressions)
  }
}

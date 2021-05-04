import Foundation

// MARK: -
/** Delegate to be notified when impressions start or end. */
public protocol ImpressionLoggerDelegate: AnyObject {

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
 Provides basic impression tracking across scrolling collection views,
 such as `UICollectionView` or `UITableView`. Works best with views that
 can provide fine-grained updates of visible cells, but can also be
 adapted to work with views that don't.

 ## Usage
 `ImpressionLogger` provides only basic impression tracking logic that
 considers a view as impressed as soon as it enters the screen. For
 more advanced functionality, see `ScrollTracker`, which offers
 visibility and time threshholds.

 Used from React Native because RN's `SectionList` and `FlatList`
 provide this advanced functionality already.

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
public final class ImpressionLogger: NSObject {

  // MARK: -
  /** Represents an impression of a cell in the collection view. */
  public struct Impression {

    /// Content that was impressed.
    public let content: Content

    /// Start time of impression.
    public let startTime: TimeInterval

    /// End time of impression, if available.
    public let endTime: TimeInterval?

    /// Duration of impression, if available.
    public var duration: TimeInterval? {
      endTime != nil ? endTime! - startTime : nil
    }
  }

  // MARK: -
  private unowned let metricsLogger: MetricsLogger

  private let clock: Clock
  private unowned let monitor: OperationMonitor
  
  private var impressionStarts: [Content: TimeInterval]

  public weak var delegate: ImpressionLoggerDelegate?

  typealias Deps = ClockSource & OperationMonitorSource

  init(metricsLogger: MetricsLogger, deps: Deps) {
    self.metricsLogger = metricsLogger
    self.clock = deps.clock
    self.monitor = deps.operationMonitor
    self.impressionStarts = [:]
  }

  /// Call this method when new items are displayed.
  @objc(collectionViewWillDisplayContent:)
  public func collectionViewWillDisplay(content: Content) {
    monitor.execute {
      broadcastStartAndAddImpressions(contentArray: [content], now: clock.now)
    }
  }

  /// Call this method when previously displayed items are hidden.
  /// If an item is reported as hidden that had not previously
  /// been displayed, the impression for that item will be ignored.
  @objc(collectionViewDidHideContent:)
  public func collectionViewDidHide(content: Content) {
    monitor.execute {
      broadcastEndAndRemoveImpressions(contentArray: [content], now: clock.now)
    }
  }

  /// Call this method when the collection view changes content, but
  /// does not provide per-item updates for the change. For example,
  /// when a collection reloads.
  @objc(collectionViewDidChangeVisibleContent:)
  public func collectionViewDidChangeVisibleContent(_ contentArray: [Content]) {
    monitor.execute {
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
  }

  /// Call this method when the collection view hides.
  @objc public func collectionViewDidHideAllContent() {
    monitor.execute {
      let keys = [Content](impressionStarts.keys)
      broadcastEndAndRemoveImpressions(contentArray: keys, now: clock.now)
    }
  }
  
  private func broadcastStartAndAddImpressions(contentArray: [Content], now: TimeInterval) {
    guard !contentArray.isEmpty else { return }
    var impressions = [Impression]()
    for content in contentArray {
      let impression = Impression(content: content, startTime: now, endTime: nil)
      impressions.append(impression)
      impressionStarts[content] = now
    }
    monitor.execute {
      for impression in impressions {
        metricsLogger.logImpression(content: impression.content)
      }
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

extension ImpressionLogger.Impression: CustomDebugStringConvertible {
  public var debugDescription: String {
    endTime != nil ? "(\(content.description), \(startTime), \(endTime!))"
      : "(\(content.description), \(startTime))"
  }
}

extension ImpressionLogger.Impression: Hashable {
  public func hash(into hasher: inout Hasher) {
    hasher.combine(content)
  }
  
  public static func == (lhs: ImpressionLogger.Impression,
                         rhs: ImpressionLogger.Impression) -> Bool {
    ((lhs.content == rhs.content) &&
     (abs(lhs.startTime - rhs.startTime) < 0.01) &&
     (abs((lhs.endTime ?? 0) - (rhs.endTime ?? 0)) < 0.01))
  }
}

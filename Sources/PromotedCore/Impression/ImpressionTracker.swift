import Foundation

// MARK: -
/** Delegate to be notified when impressions start or end. */
public protocol ImpressionTrackerDelegate: AnyObject {

  /// Notifies delegate of impression starts.
  func impressionTracker(
    _ impressionTracker: ImpressionTracker,
    didStartImpressions impressions: [ImpressionTracker.Impression]
  )
  
  /// Notifies delegate of impression ends.
  func impressionTracker(
    _ impressionTracker: ImpressionTracker,
    didEndImpressions impressions: [ImpressionTracker.Impression]
  )
}

// MARK: -
/**
 Provides basic impression tracking across scrolling collection views,
 such as `UICollectionView` or `UITableView`. Works best with views that
 can provide fine-grained updates of visible cells, but can also be
 adapted to work with views that don't (see `ScrollTracker`).

 Uses `MetricsLogger` to send impression events to backends. You can also
 use `logImpression()` on `MetricsLogger` directly to send individual
 impression events if you don't need to track a scrolling collection view.

 ## Usage
 `ImpressionTracker` provides only basic impression tracking logic that
 considers a view as impressed as soon as it enters the screen. For
 more advanced functionality, see `ScrollTracker`, which offers
 visibility and time threshholds.

 Used from React Native because RN's `SectionList` and `FlatList`
 provide this advanced functionality already.

 Clients should create an instance of `ImpressionTracker`
 and reference it in their view controller, then provide updates
 to the impression logger as the collection view scrolls or updates.
 
 # Example:
 ```swift
 class MyViewController: UIViewController {
   var collectionView: UICollectionView
   var impressionTracker: ImpressionTracker
 
   init(...) {
     impressionTracker = metricsLoggerService.impressionTracker()
   }

   private func content(atIndexPath path: IndexPath) -> Content? {
     let item = path.item
     if item >= self.items.count { return nil }
     let myItemProperties = self.items[item]
     return Item(properties: myItemProperties)
   }

   func viewWillDisappear(_ animated: Bool) {
     impressionTracker.collectionViewDidHideAllContent()
   }

   func collectionView(_ collectionView: UICollectionView,
                       willDisplay cell: UICollectionViewCell,
                       forItemAt indexPath: IndexPath) {
     if let content = content(atIndexPath: indexPath) {
       impressionTracker.collectionViewWillDisplay(content: content)
     }
   }
    
   func collectionView(_ collectionView: UICollectionView,
                       didEndDisplaying cell: UICollectionViewCell,
                       forItemAt indexPath: IndexPath) {
     if let content = content(atIndexPath: indexPath) {
       impressionTracker.collectionViewDidHide(content: content)
     }
   }

   func reloadCollectionView() {
     self.collectionView.reloadData()
     let visibleContent = collectionView.indexPathsForVisibleItems.map {
       path in content(atIndexPath: path)
     };
     impressionTracker.collectionViewDidChangeVisibleContent(visibleContent)
   }
 }
 ```
 */
@objc(PROImpressionTracker)
public final class ImpressionTracker: NSObject, ImpressionConfig {

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

    /// Source type of impression.
    public let sourceType: ImpressionSourceType
  }

  // MARK: - Properties
  private unowned let metricsLogger: MetricsLogger

  private let clock: Clock
  private unowned let monitor: OperationMonitor
  
  private var contentToImpressionStart: [Content: TimeInterval]
  private var contentToImpressionID: [Content: String]
  private var sourceType: ImpressionSourceType

  public weak var delegate: ImpressionTrackerDelegate?

  typealias Deps = ClockSource & OperationMonitorSource

  init(metricsLogger: MetricsLogger, deps: Deps) {
    self.metricsLogger = metricsLogger
    self.clock = deps.clock
    self.monitor = deps.operationMonitor
    self.contentToImpressionStart = [:]
    self.contentToImpressionID = [:]
    self.sourceType = .unknown
  }
}

// MARK: - Collection Tracking
public extension ImpressionTracker {

  /// Call this method when new items are displayed.
  @objc(collectionViewWillDisplayContent:)
  func collectionViewWillDisplay(content: Content) {
    monitor.execute {
      broadcastStartAndAddImpressions(contents: [content], now: clock.now)
    }
  }

  /// Call this method when previously displayed items are hidden.
  /// If an item is reported as hidden that had not previously
  /// been displayed, the impression for that item will be ignored.
  @objc(collectionViewDidHideContent:)
  func collectionViewDidHide(content: Content) {
    monitor.execute {
      broadcastEndAndRemoveImpressions(contents: [content], now: clock.now)
    }
  }

  @objc(collectionViewDidChangeVisibleContent:)
  func collectionViewDidChangeVisibleContent(array contentArray: [Content]) {
    collectionViewDidChangeVisibleContent(contentArray)
  }

  /// Call this method when the collection view changes content, but
  /// does not provide per-item updates for the change. For example,
  /// when a collection reloads.
  func collectionViewDidChangeVisibleContent<T: Collection>(
    _ contents: T
  ) where T.Element == Content {
    monitor.execute {
      let now = clock.now
      let newlyShownContent = contents.filter {
        contentToImpressionStart[$0] == nil
      }
      // TODO(yu-hong): Below is potentially O(n^2), but in practice,
      // the arrays are pretty small.
      let newlyHiddenContent = contentToImpressionStart.keys.filter {
        !contents.contains($0)
      }
      broadcastStartAndAddImpressions(contents: newlyShownContent, now: now)
      broadcastEndAndRemoveImpressions(contents: newlyHiddenContent, now: now)
    }
  }

  /// Call this method when the collection view hides.
  @objc func collectionViewDidHideAllContent() {
    monitor.execute {
      broadcastEndAndRemoveImpressions(
        contents: contentToImpressionStart.keys,
        now: clock.now
      )
    }
  }

  private func broadcastStartAndAddImpressions<T: Collection>(
    contents: T,
    now: TimeInterval
  ) where T.Element == Content {
    guard !contents.isEmpty else { return }
    let impressions = contents.map { content in
      Impression(
        content: content,
        startTime: now,
        endTime: nil,
        sourceType: sourceType
      )
    }
    for content in contents {
      contentToImpressionStart[content] = now
    }
    monitor.execute {
      for impression in impressions {
        let content = impression.content
        let impressionProto = metricsLogger.logImpression(
          content: content,
          sourceType: impression.sourceType
        )
        contentToImpressionID[content] = impressionProto.impressionID
      }
    }
    delegate?.impressionTracker(self, didStartImpressions: impressions)
  }

  private func broadcastEndAndRemoveImpressions<T: Collection>(
    contents: T,
    now: TimeInterval
  ) where T.Element == Content {
    guard !contents.isEmpty else { return }
    let impressions =
      zip(
        contents,
        contents.map { contentToImpressionStart.removeValue(forKey: $0) }
      )
      .filter { $0.1 != nil }
      .map {
        Impression(
          content: $0.0,
          startTime: $0.1!,
          endTime: now,
          sourceType: sourceType
        )
      }
    for content in contents {
      contentToImpressionID.removeValue(forKey: content)
    }
    // Not calling `metricsLogger`. No logging end impressions for now.
    delegate?.impressionTracker(self, didEndImpressions: impressions)
  }
}

// MARK: - Impression ID
public extension ImpressionTracker {
  func impressionID(for content: Content) -> String? {
    contentToImpressionID[content]
  }
}

// MARK: - ImpressionConfig
public extension ImpressionTracker {
  @discardableResult
  func with(sourceType: ImpressionSourceType) -> Self {
    self.sourceType = sourceType
    return self
  }
}

// MARK: - Impression CustomDebugStringConvertible
extension ImpressionTracker.Impression: CustomDebugStringConvertible {
  public var debugDescription: String {
    endTime != nil
      ? "(\(content.description), \(startTime), \(endTime!), \(sourceType))"
      : "(\(content.description), \(startTime), \(sourceType))"
  }
}

// MARK: - Impression Hashable
extension ImpressionTracker.Impression: Hashable {
  public func hash(into hasher: inout Hasher) {
    hasher.combine(content)
    hasher.combine(sourceType)
  }
  
  public static func == (lhs: ImpressionTracker.Impression,
                         rhs: ImpressionTracker.Impression) -> Bool {
    (lhs.content == rhs.content) &&
    (abs(lhs.startTime - rhs.startTime) < 0.01) &&
    (abs((lhs.endTime ?? 0) - (rhs.endTime ?? 0)) < 0.01) &&
    (lhs.sourceType == rhs.sourceType)
  }
}

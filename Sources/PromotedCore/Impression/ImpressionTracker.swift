import Foundation
import os.log

// MARK: -
/** Delegate to be notified when impressions start or end. */
public protocol ImpressionTrackerDelegate: AnyObject {

  /// Notifies delegate of impression starts.
  func impressionTracker(
    _ impressionTracker: ImpressionTracker,
    didStartImpressions impressions: [ImpressionTracker.Impression],
    autoViewState: AutoViewState
  )
  
  /// Notifies delegate of impression ends.
  func impressionTracker(
    _ impressionTracker: ImpressionTracker,
    didEndImpressions impressions: [ImpressionTracker.Impression],
    autoViewState: AutoViewState
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

   func collectionView(
     _ collectionView: UICollectionView,
     willDisplay cell: UICollectionViewCell,
     forItemAt indexPath: IndexPath
   ) {
     if let content = content(atIndexPath: indexPath) {
       impressionTracker.collectionViewWillDisplay(content: content)
     }
   }
    
   func collectionView(
     _ collectionView: UICollectionView,
     didEndDisplaying cell: UICollectionViewCell,
     forItemAt indexPath: IndexPath
   ) {
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
public final class ImpressionTracker: NSObject {

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

    /// Interaction that caused the impression.
    public let userInteraction: UserInteraction?
  }

  // MARK: -
  private struct PartialImpression {
    let startTime: TimeInterval
    let impressionID: String
    let userInteraction: UserInteraction?
  }

  // MARK: - Properties
  private unowned let metricsLogger: MetricsLogger

  private let clock: Clock
  private unowned let monitor: OperationMonitor
  
  private let sourceType: ImpressionSourceType
  private var contentToPartialImpression: [Content: PartialImpression]

  public weak var delegate: ImpressionTrackerDelegate?

  typealias Deps = ClockSource & OperationMonitorSource

  init(
    metricsLogger: MetricsLogger,
    sourceType: ImpressionSourceType,
    deps: Deps
  ) {
    self.metricsLogger = metricsLogger
    self.sourceType = sourceType
    self.clock = deps.clock
    self.monitor = deps.operationMonitor
    self.contentToPartialImpression = [:]
  }
}

// MARK: - Collection Tracking
public extension ImpressionTracker {

  /// Call this method when new items are displayed.
  func collectionViewWillDisplay(
    content: Content,
    autoViewState: AutoViewState,
    userInteraction: UserInteraction? = nil
  ) {
    monitor.execute {
      broadcastStartAndAddImpressions(
        contents: [content],
        contentToUserInteraction: (
          userInteraction != nil ?
          [content: userInteraction!] :
          nil
        ),
        autoViewState: autoViewState,
        now: clock.now
      )
    }
  }

  /// Call this method when previously displayed items are hidden.
  /// If an item is reported as hidden that had not previously
  /// been displayed, the impression for that item will be ignored.
  func collectionViewDidHide(
    content: Content,
    autoViewState: AutoViewState
  ) {
    monitor.execute {
      broadcastEndAndRemoveImpressions(
        contents: [content],
        autoViewState: autoViewState,
        now: clock.now
      )
    }
  }

  /// Call this method when the collection view changes content, but
  /// does not provide per-item updates for the change. For example,
  /// when a collection reloads.
  func collectionViewDidChangeVisibleContent<T: Collection>(
    _ contents: T,
    autoViewState: AutoViewState
  ) where T.Element == Content {
    collectionViewDidChangeVisibleContent(
      contents: contents,
      contentToUserInteraction: nil,
      autoViewState: autoViewState
    )
  }

  /// Call this method when the collection view changes content, but
  /// does not provide per-item updates for the change. For example,
  /// when a collection reloads.
  ///
  /// This version passes a dictionary of `Content` to `UserInteraction`
  /// which is used for diagnostic logging. Prefer to use the version
  /// of this method without `UserInteraction` if you don't need
  /// diagnostics, because that version is more efficient.
  func collectionViewDidChangeVisibleContent(
    _ contentsAndUserInteractions: [Content: UserInteraction],
    autoViewState: AutoViewState
  ) {
    collectionViewDidChangeVisibleContent(
      contents: contentsAndUserInteractions.keys,
      contentToUserInteraction: contentsAndUserInteractions,
      autoViewState: autoViewState
    )
  }

  private func collectionViewDidChangeVisibleContent<T: Collection>(
    contents: T,
    contentToUserInteraction: [Content: UserInteraction]?,
    autoViewState: AutoViewState
  ) where T.Element == Content {
    monitor.execute {
      let now = clock.now
      let newlyShownContent = contents
        .filter { contentToPartialImpression[$0] == nil }
      // TODO(yuhong): Below is potentially O(n^2), but in practice,
      // the arrays are pretty small.
      let newlyHiddenContent = contentToPartialImpression
        .filter { !contents.contains($0.key) }
        .map { $0.key }
      broadcastStartAndAddImpressions(
        contents: newlyShownContent,
        contentToUserInteraction: contentToUserInteraction,
        autoViewState: autoViewState,
        now: now
      )
      broadcastEndAndRemoveImpressions(
        contents: newlyHiddenContent,
        autoViewState: autoViewState,
        now: now
      )
    }
  }

  /// Call this method when the collection view hides.
  func collectionViewDidHideAllContent(autoViewState: AutoViewState) {
    monitor.execute {
      broadcastEndAndRemoveImpressions(
        contents: contentToPartialImpression.keys,
        autoViewState: autoViewState,
        now: clock.now
      )
    }
  }

  private func broadcastStartAndAddImpressions<T: Collection>(
    contents: T,
    contentToUserInteraction: [Content: UserInteraction]?,
    autoViewState: AutoViewState,
    now: TimeInterval
  ) where T.Element == Content {
    guard !contents.isEmpty else { return }
    let impressions = contents
      .map { content in
        Impression(
          content: content,
          startTime: now,
          endTime: nil,
          sourceType: sourceType,
          userInteraction: contentToUserInteraction?[content]
        )
      }
    monitor.execute {
      for impression in impressions {
        let content = impression.content
        let impressionProto = metricsLogger.logImpression(
          content: content,
          sourceType: impression.sourceType,
          autoViewState: autoViewState,
          userInteraction: impression.userInteraction
        )
        contentToPartialImpression[content] = PartialImpression(
          startTime: now,
          impressionID: impressionProto.impressionID,
          userInteraction: impression.userInteraction
        )
      }
    }
    delegate?.impressionTracker(
      self,
      didStartImpressions: impressions,
      autoViewState: autoViewState
    )
  }

  private func broadcastEndAndRemoveImpressions<T: Collection>(
    contents: T,
    autoViewState: AutoViewState,
    now: TimeInterval
  ) where T.Element == Content {
    guard !contents.isEmpty else { return }
    let impressions: [Impression] = contents.compactMap { content in
      let p = contentToPartialImpression.removeValue(forKey: content)
      guard let partial = p else { return nil }
      return Impression(
        content: content,
        startTime: partial.startTime,
        endTime: now,
        sourceType: sourceType,
        userInteraction: partial.userInteraction
      )
    }
    for content in contents {
      contentToPartialImpression.removeValue(forKey: content)
    }
    // Not calling `metricsLogger`. No logging end impressions for now.
    delegate?.impressionTracker(
      self,
      didEndImpressions: impressions,
      autoViewState: autoViewState
    )
  }
}

// MARK: - Impression ID
public extension ImpressionTracker {
  func impressionID(for content: Content) -> String? {
    contentToPartialImpression[content]?.impressionID
  }
}

// MARK: - Debug
/** Use this class in conjunction with OSLog to show impressions. */
public class ImpressionTrackerDebugLogger: ImpressionTrackerDelegate {

  private let osLog: OSLog

  public init(osLog: OSLog) {
    self.osLog = osLog
  }

  public func impressionTracker(
    _ impressionTracker: ImpressionTracker,
    didStartImpressions impressions: [ImpressionTracker.Impression],
    autoViewState: AutoViewState
  ) {
    for impression in impressions {
      osLog.debug(
        "Impression: %{private}@ autoViewState: %{private}@",
        impression.debugDescription,
        autoViewState.debugDescription
      )
    }
  }

  public func impressionTracker(
    _ impressionTracker: ImpressionTracker,
    didEndImpressions impressions: [ImpressionTracker.Impression],
    autoViewState: AutoViewState
  ) {
    // no-op
  }
}

// MARK: - Impression CustomDebugStringConvertible
extension ImpressionTracker.Impression: CustomDebugStringConvertible {
  public var debugDescription: String {
    let contents = [
      content.debugDescription,
      startTime.asFormattedDateSince1970(),
      endTime?.asFormattedDateSince1970(),
      sourceType,
      userInteraction
    ] as [Any?]
    return "(" +
      contents
        .compactMap { $0 != nil ? String(describing: $0!) : nil }
        .joined(separator: ", ") +
    ")"
  }
}

// MARK: - Impression Hashable
extension ImpressionTracker.Impression: Hashable {
  public func hash(into hasher: inout Hasher) {
    hasher.combine(content)
    hasher.combine(sourceType)
    hasher.combine(userInteraction)
  }
  
  public static func == (
    lhs: ImpressionTracker.Impression,
    rhs: ImpressionTracker.Impression
  ) -> Bool {
    (lhs.content == rhs.content) &&
    (abs(lhs.startTime - rhs.startTime) < 0.01) &&
    (abs((lhs.endTime ?? 0) - (rhs.endTime ?? 0)) < 0.01) &&
    (lhs.sourceType == rhs.sourceType) &&
    (lhs.userInteraction == rhs.userInteraction)
  }
}

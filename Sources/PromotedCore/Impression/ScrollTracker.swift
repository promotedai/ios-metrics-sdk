import CoreGraphics
import Foundation
import UIKit

// MARK: - ScrollTracker
/**
 Tracks scrolling behavior in client apps to deliver accurate impression
 events.
 
 "Accurate" in this case means that the views scrolled on screen meet the
 following criteria.
 
 1. Ratio of view displayed on screen is at least
    `ClientConfig.scrollTrackerVisibilityThreshold`.
 2. (Coming later) Duration of impression is at least
    `ClientConfig.scrollTrackerDurationThreshold`.
 
 ## Suggested usage pattern
 
 Define the **scroll view** as the outermost scrolling view, and
 the **content view(s)** as the view(s) contained within the scroll view
 whose impressions you wish to track. These may be the same view, in the
 case of a single scrolling `UICollectionView`, or these may be different
 views, in the case of a scroll view containing many table/collection views.
 
 Suggested usage pattern is for the logic that creates the scroll view
 to initialize `ScrollTracker` and pass it to the logic to populate the
 bounds for the content in the content view.
 
 ```swift
 class ScrollViewController {
   func viewDidLoad() {
     self.scrollTracker = service.scrollTracker()
     self.contentViewController = ContentViewController()
     self.contentViewController.scrollTracker = self.scrollTracker
   }
 }
 class ContentViewController {
   var scrollTracker: ScrollTracker
   func viewDidLayoutSubviews() {
     // This must be done after layout is complete.
     for (content, frame) in self.content {
       self.scrollTracker.setFrame(frame, forContent: content)
     }
   }
 }
 ```
 
 ## Performance vs accuracy
 
 `ScrollTracker` works by coalescing scroll events to achieve a balance
 between performance and accuracy. The more often `ScrollTracker` processes
 scroll events, the more accurately impressions are tracked, but this comes
 at a performance cost. Although this cost is usually negligible relative
 to the amount of computation in most UI updates, `ScrollTracker` minimizes
 this overhead by updating at a fixed frequency rather than in response to
 every scroll event. This update frequency is controlled via
 `ClientConfig.scrollTrackerUpdateFrequency`.
 
 ## UIKit specialization
 
 Although `ScrollTracker` is designed for use with both UIKit and React
 Native, we provide UIKit specializations for tracking `UIScrollView`s and
 `UICollectionView`s. These specializations use KVO on `UIView`s to eliminate
 the need to call `scrollViewDidScroll()` on `ScrollTracker`, and to wait for
 layout to update frames. To do the latter, call `setFramesFrom*` after the
 content view's content is loaded, and the frames will be automatically
 calculated when layout on the content view completes.
 
 `ScrollTracker` initiates KVO on provided `UIView`s when used in this
 capacity. Releasing all references to `ScrollTracker` will stop KVO.
 
 Because of this KVO usage, if you wish to track multiple distinct
 `UICollectionView`s within a single `UIScrollView`, create a new
 `ScrollTracker` for each `UICollectionView` that you wish to track.
 
 ## React Native
 
 Use the `useImpressionTracker()` hook for accurate tracking in `FlatList`s
 and `SectionList`s. If using some other kind of scroll view, set the scroll
 view's viewport manually through the `viewport` property when the scroll
 view updates.
 */
@objc(PROScrollTracker)
public final class ScrollTracker: NSObject, ImpressionConfig {

  private let visibilityThreshold: Float
  private let durationThreshold: TimeInterval
  private let updateFrequency: TimeInterval

  private let clock: Clock
  private unowned let metricsLogger: MetricsLogger
  private unowned let monitor: OperationMonitor

  private let impressionTracker: ImpressionTracker
  private var content: [(CGRect, Content)]
  private var timer: ScheduledTimer?

  /// Scroll view that user interacts with.
  public unowned var scrollView: UIScrollView? {
    didSet {
      scrollViewOffsetObservation = scrollView?.observe(\.contentOffset) {
        [weak self] _, _ in
        self?.scrollViewDidScroll()
      }
    }
  }

  /// Collection view with content to log. Must be contained in
  /// `scrollView`, or the same view as `scrollView`.
  public unowned var collectionView: UICollectionView? {
    didSet { collectionViewLayoutObservation = nil }
  }

  private var collectionViewLayoutObservation: NSKeyValueObservation?
  private var scrollViewOffsetObservation: NSKeyValueObservation?

  /// Viewport of scroll view, based on scroll view's coord system.
  /// Under UIKit and React Native, this corresponds to the viewport
  /// of the scroll view as reported by scroll events. Changing this
  /// property will automatically schedule an update.
  public var viewport: CGRect {
    didSet { maybeScheduleUpdateVisibilityTimer() }
  }

  typealias Deps = ClientConfigSource & ClockSource & OperationMonitorSource

  init(metricsLogger: MetricsLogger, deps: Deps) {
    self.clock = deps.clock
    let clientConfig = deps.clientConfig
    self.visibilityThreshold = clientConfig.scrollTrackerVisibilityThreshold
    self.durationThreshold = clientConfig.scrollTrackerDurationThreshold
    self.updateFrequency = clientConfig.scrollTrackerUpdateFrequency
    self.metricsLogger = metricsLogger
    self.monitor = deps.operationMonitor
    self.impressionTracker = ImpressionTracker(metricsLogger: metricsLogger, deps: deps)
    self.content = []
    self.timer = nil
    self.viewport = CGRect.zero
  }

  @objc public func clearContent() {
    content.removeAll()
  }
  
  @objc public func setFrame(_ frame: CGRect, forContent content: Content) {
    self.content.append((frame, content))
  }

  @objc public func scrollViewDidHideAllContent() {
    impressionTracker.collectionViewDidHideAllContent(autoViewID: nil)
  }

  private func maybeScheduleUpdateVisibilityTimer() {
    if timer != nil { return }
    timer = clock.schedule(timeInterval: updateFrequency) { [weak self] _ in
      guard let strongSelf = self else { return }
      strongSelf.timer = nil
      strongSelf.updateVisibility()
    }
  }

  private func updateVisibility() {
    monitor.execute {
      var visibleContent = [Content]()
      // TODO(yu-hong): Replace linear search with binary/interpolation search
      // for larger inputs. Need a secondary data structure to sort frames.
      for (frame, content) in content {
        let overlapRatio = frame.overlapRatio(viewport)
        if overlapRatio >= visibilityThreshold {
          visibleContent.append(content)
        }
      }
      impressionTracker.collectionViewDidChangeVisibleContent(
        visibleContent,
        autoViewID: nil
      )
    }
  }
}

// MARK: - UIKit: UICollectionView/UIScrollView
extension ScrollTracker {

  convenience init(metricsLogger: MetricsLogger,
                   collectionView: UICollectionView,
                   deps: Deps) {
    self.init(metricsLogger: metricsLogger, deps: deps)
    set(scrollView: collectionView, collectionView: collectionView)
  }
  
  convenience init(metricsLogger: MetricsLogger,
                   scrollView: UIScrollView,
                   deps: Deps) {
    self.init(metricsLogger: metricsLogger, deps: deps)
    set(scrollView: scrollView, collectionView: nil)
  }
}

// MARK: - UIKit support
public extension ScrollTracker {
  private func set(scrollView: UIScrollView, collectionView: UICollectionView?) {
    self.scrollView = scrollView
    self.collectionView = collectionView
  }

  @objc(setFramesFromCollectionView:dataSource:)
  func setFramesFrom(collectionView: UICollectionView, dataSource: IndexPathDataSource) {
    self.collectionView = collectionView
    setFramesFrom(dataSource: dataSource)
  }

  @objc(setFramesFromDataSource:)
  func setFramesFrom(dataSource: IndexPathDataSource) {
    assert(collectionView != nil)
    setFramesOnCollectionViewLayout { dataSource.contentFor(indexPath: $0) }
  }
  
  @objc(setFramesFromCollectionView:content:)
  func setFramesFrom(collectionView: UICollectionView, content: [Content]) {
    self.collectionView = collectionView
    setFramesFrom(content: content)
  }

  @objc(setFramesFromContent:)
  func setFramesFrom(content: [Content]) {
    assert(collectionView?.numberOfSections == 1)
    setFramesOnCollectionViewLayout { $0.item < content.count ? content[$0.item] : nil }
  }
  
  private func setFramesOnCollectionViewLayout(
      dataProducer: @escaping (IndexPath) -> Content?) {
    collectionViewLayoutObservation = collectionView?.observe(\.contentSize) {
      [weak self] _, _ in
      guard let strongSelf = self else { return }
      strongSelf.collectionViewLayoutObservation = nil
      strongSelf.setFrames(dataProducer: dataProducer)
    }
  }
  
  private func setFrames(dataProducer: @escaping (IndexPath) -> Content?) {
    monitor.execute {
      guard let collectionView = collectionView else { return }
      guard collectionView.window != nil else { return }
      content.removeAll()
      let layout = collectionView.collectionViewLayout
      for section in 0 ..< collectionView.numberOfSections {
        for item in 0 ..< collectionView.numberOfItems(inSection: section) {
          let path = IndexPath(item: item, section: section)
          guard let attrs = layout.layoutAttributesForItem(at: path) else { continue }
          guard let content = dataProducer(path) else { continue }
          let frame = attrs.frame
          guard !frame.isEmpty else { continue }
          setFrame(frame, forContent: content)
        }
      }
      // This should happen after layout is complete. Log initial viewport.
      scrollViewDidChangeVisibleContent()
    }
  }

  @objc func scrollViewDidScroll() {
    scrollViewDidChangeVisibleContent()
  }
  
  @objc func scrollViewDidChangeVisibleContent() {
    guard let scrollView = scrollView else { return }
    guard let collectionView = collectionView else { return }
    guard scrollView.window != nil && collectionView.window != nil else { return }
    let origin = scrollView.convert(scrollView.contentOffset, to: collectionView);
    let size = scrollView.frame.size
    viewport = CGRect(origin: origin, size: size)
  }
}

// MARK: - ImpressionConfig
public extension ScrollTracker {
  @discardableResult
  func with(sourceType: ImpressionSourceType) -> Self {
    impressionTracker.with(sourceType: sourceType)
    return self
  }
}

// MARK: - Testing
extension ScrollTracker {
  var contentForTesting: [(CGRect, Content)] { content }
}

// MARK: - CGRect extension
extension CGRect {
  var area: Float { Float(width * height) }
  
  func overlapRatio(_ other: CGRect) -> Float {
    let area = self.area
    if area == 0 { return 0 }
    let intersection = self.intersection(other)
    return intersection.area / area
  }
}

import CoreGraphics
import Foundation

// MARK: -
@objc(PROScrollTracker)
public class ScrollTracker: NSObject {
  
  private static let visibilityThreshold: Float = 0.5
  private static let updateThreshold: TimeInterval = 0.5
  
  private let clock: Clock
  private let metricsLogger: MetricsLogger
  
  private var impressionLogger: ImpressionLogger
  /*visibleForTesting*/ private(set) var contentToFrame: [Content: CGRect]
  private var timer: ScheduledTimer?
  
  #if canImport(UIKit)
  public unowned var scrollView: UIScrollView? {
    didSet {
      scrollViewOffsetObservation = scrollView?.observe(\.contentOffset) { [weak self] _, _ in
        self?.scrollViewDidScroll()
      }
    }
  }
  public unowned var collectionView: UICollectionView? {
    didSet { collectionViewLayoutObservation = nil }
  }
  private var collectionViewLayoutObservation: NSKeyValueObservation?
  private var scrollViewOffsetObservation: NSKeyValueObservation?
  #endif
  
  /// Viewport of scroll view, based on scroll view's coord system.
  /// Under UIKit and React Native, this corresponds to the viewport
  /// of the scroll view as reported by scroll events.
  public var viewport: CGRect {
    didSet { maybeScheduleUpdateVisibilityTimer() }
  }
  
  #if canImport(UIKit)
  convenience init(metricsLogger: MetricsLogger,
                   clock: Clock,
                   collectionView: UICollectionView) {
    self.init(metricsLogger: metricsLogger, clock: clock)
    set(scrollView: collectionView, collectionView: collectionView)
  }
  
  convenience init(metricsLogger: MetricsLogger,
                   clock: Clock,
                   scrollView: UIScrollView) {
    self.init(metricsLogger: metricsLogger, clock: clock)
    set(scrollView: scrollView, collectionView: nil)
  }

  private func set(scrollView: UIScrollView, collectionView: UICollectionView?) {
    self.scrollView = scrollView
    self.collectionView = collectionView
  }
  #endif

  init(metricsLogger: MetricsLogger, clock: Clock) {
    self.clock = clock
    self.metricsLogger = metricsLogger
    self.impressionLogger = ImpressionLogger(metricsLogger: metricsLogger, clock: clock)
    self.contentToFrame = [:]
    self.timer = nil
    self.viewport = CGRect.zero
  }
  
  @objc public func clearContent() {
    contentToFrame.removeAll()
  }
  
  @objc public func setFrame(_ frame: CGRect, forContent content: Content) {
    contentToFrame[content] = frame
  }

  @objc public func scrollViewDidHideAllContent() {
    impressionLogger.collectionViewDidHideAllContent()
  }

  private func maybeScheduleUpdateVisibilityTimer() {
    if timer != nil { return }
    timer = clock.schedule(timeInterval: Self.updateThreshold) { [weak self] _ in
      guard let strongSelf = self else { return }
      strongSelf.timer = nil
      strongSelf.updateVisibility()
    }
  }

  private func updateVisibility() {
    var visibleContent = [Content]()
    // TODO(yu-hong): Replace linear search with binary/interpolation search
    // for larger inputs. Need a secondary data structure to sort frames.
    for (content, frame) in contentToFrame {
      let overlapRatio = frame.overlapRatio(viewport)
      if overlapRatio >= Self.visibilityThreshold {
        visibleContent.append(content)
      }
    }
    impressionLogger.collectionViewDidChangeVisibleContent(visibleContent)
  }
}

// MARK: - UIKit: UICollectionView/UIScrollView
#if canImport(UIKit)
import UIKit

public extension ScrollTracker {

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
  
  private func setFramesOnCollectionViewLayout(dataProducer: @escaping (IndexPath) -> Content?) {
    collectionViewLayoutObservation = collectionView?.observe(\.contentSize) { [weak self] _, _ in
      guard let strongSelf = self else { return }
      strongSelf.collectionViewLayoutObservation = nil
      strongSelf.setFrames(dataProducer: dataProducer)
    }
  }
  
  private func setFrames(dataProducer: @escaping (IndexPath) -> Content?) {
    guard let collectionView = collectionView else { return }
    guard collectionView.window != nil else { return }
    contentToFrame.removeAll()
    let layout = collectionView.collectionViewLayout
    for section in 0 ..< collectionView.numberOfSections {
      for item in 0 ..< collectionView.numberOfItems(inSection: section) {
        let path = IndexPath(item: item, section: section)
        guard let attrs = layout.layoutAttributesForItem(at: path) else { continue }
        guard let content = dataProducer(path) else { continue }
        let frame = attrs.frame
        guard frame.area > 0 else { continue }
        setFrame(frame, forContent: content)
      }
    }
    // This should happen after layout is complete. Log initial viewport.
    scrollViewDidChangeVisibleContent()
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
#endif

// MARK: -
extension CGRect {
  var area: Float {
    return Float(width * height)
  }
  
  func overlapRatio(_ other: CGRect) -> Float {
    let area = self.area
    if area == 0 { return 0 }
    let intersection = self.intersection(other)
    return intersection.area / area
  }
}

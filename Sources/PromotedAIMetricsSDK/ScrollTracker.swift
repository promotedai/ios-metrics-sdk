import CoreGraphics
import Foundation

public class ScrollTracker {
  
  private static let visibilityThreshold: Float = 0.5
  private static let updateThreshold: TimeInterval = 0.5
  
  private let clock: Clock
  private let metricsLogger: MetricsLogger
  
  private var impressionLogger: ImpressionLogger?
  /*visibleForTesting*/ private(set) var frames: [[CGRect]]
  private var contentToIndexPath: [Content: IndexPath]
  private var timer: ScheduledTimer?
  
  /// Viewport of scroll view, based on scroll view's coord system.
  /// Under UIKit and React Native, this corresponds to the viewport
  /// of the scroll view as reported by scroll events.
  public var viewport: CGRect {
    didSet { maybeScheduleUpdateVisibilityTimer() }
  }
  
  /// Top left of scroll view in screen coordinates.
  public var offset: CGPoint
  
  /// Content for scroll view.
  public var sectionedContent: [[Content]] {
    didSet {
      invalidateImpressionLogger()
      syncWithSectionedContent()
    }
  }

  init(metricsLogger: MetricsLogger, clock: Clock) {
    self.clock = clock
    self.metricsLogger = metricsLogger
    
    self.impressionLogger = nil
    self.frames = []
    self.contentToIndexPath = [Content: IndexPath]()
    self.timer = nil
    
    self.viewport = CGRect.zero
    self.offset = CGPoint.zero
    self.sectionedContent = []
  }
  
  public func setFrame(_ frame: CGRect, forContentAtIndex index: IndexPath) {
    index.setValue(frame, inArray: &frames)
  }
  
  public func setFrame(_ frame: CGRect, forContent content: Content) {
    if let path = contentToIndexPath[content] {
      self.setFrame(frame, forContentAtIndex: path)
    }
  }
  
  private func syncWithSectionedContent() {
    let previousFrames = frames
    var frames: [[CGRect]] = []
    var contentToIndexPath = [Content: IndexPath]()
    for (sectionIndex, section) in sectionedContent.enumerated() {
      frames.append([CGRect](repeating: CGRect.zero, count: section.count))
      for (itemIndex, item) in section.enumerated() {
        let indexPath = IndexPath(indexes: [sectionIndex, itemIndex])
        contentToIndexPath[item] = indexPath
        // If there's an existing frame at indexPath, re-use it.
        if let previousFrame = indexPath.valueFromArray(previousFrames) {
          indexPath.setValue(previousFrame, inArray: &frames)
        }
      }
    }
    self.frames = frames
    self.contentToIndexPath = contentToIndexPath
  }

  private func ensureImpressionLogger() -> ImpressionLogger {
    if let logger = impressionLogger { return logger }
    impressionLogger = ImpressionLogger(sectionedContent: sectionedContent,
                                        metricsLogger: metricsLogger,
                                        clock: clock)
    return impressionLogger!
  }
  
  private func invalidateImpressionLogger() {
    impressionLogger = nil
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
    var visibleContent = [IndexPath]()
    var offsetViewport = viewport
    offsetViewport.origin.x += offset.x
    offsetViewport.origin.y += offset.y
    // TODO: For large content, binary or interpolation search.
    outerLoop:
    for (sectionIndex, section) in frames.enumerated() {
      for (frameIndex, frame) in section.enumerated() {
        let overlapRatio = frame.overlapRatio(offsetViewport)
        if overlapRatio >= Self.visibilityThreshold {
          visibleContent.append(IndexPath(indexes: [sectionIndex, frameIndex]))
        } else if !visibleContent.isEmpty {
          break outerLoop
        }
      }
    }
    ensureImpressionLogger().collectionViewDidChangeVisibleContent(atIndexes: visibleContent)
  }
}

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

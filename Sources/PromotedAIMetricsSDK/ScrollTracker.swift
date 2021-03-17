import CoreGraphics
import Foundation

@objc public class ScrollTracker: NSObject {
  
  private static let visibilityThreshold: Float = 0.5
  private static let updateThreshold: TimeInterval = 0.5
  
  private let impressionLogger: ImpressionLogger
  private let clock: Clock
  
  @objc public var viewport: CGRect {
    didSet { maybeScheduleUpdateVisibilityTimer() }
  }

  /*visibleForTesting*/ private(set) var frames: [[CGRect]]
  private let contentToIndexPath: [Content: IndexPath]
  private var timer: ScheduledTimer?
  
  init(sectionedContent: [[Content]], impressionLogger: ImpressionLogger, clock: Clock) {
    self.impressionLogger = impressionLogger
    self.clock = clock
    self.viewport = CGRect.zero
    self.frames = []
    var contentToIndexPath = [Content: IndexPath]()
    for (sectionIndex, section) in sectionedContent.enumerated() {
      self.frames.append([CGRect](repeating: CGRect.zero, count: section.count))
      for (itemIndex, item) in section.enumerated() {
        contentToIndexPath[item] = IndexPath(indexes: [sectionIndex, itemIndex])
      }
    }
    self.contentToIndexPath = contentToIndexPath
    self.timer = nil
  }
  
  @objc public func setFrame(_ frame: CGRect, forContentAtIndex index: IndexPath) {
    index.setValue(frame, inArray: &frames)
  }
  
  @objc public func setFrame(_ frame: CGRect, forContent content: Content) {
    if let path = contentToIndexPath[content] {
      self.setFrame(frame, forContentAtIndex: path)
    }
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
    // TODO: For large content, binary or interpolation search.
    outerLoop:
    for (sectionIndex, section) in frames.enumerated() {
      for (frameIndex, frame) in section.enumerated() {
        let overlapRatio = frame.overlapRatio(viewport)
        if overlapRatio >= Self.visibilityThreshold {
          visibleContent.append(IndexPath(indexes: [sectionIndex, frameIndex]))
        } else if !visibleContent.isEmpty {
          break outerLoop
        }
      }
    }
    impressionLogger.collectionViewDidChangeVisibleContent(atIndexes: visibleContent)
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

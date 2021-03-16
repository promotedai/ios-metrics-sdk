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
  private let contentToIndexPath: [Item: IndexPath]
  private var timer: ScheduledTimer?
  
  init(sectionedArray: [[Item]], impressionLogger: ImpressionLogger, clock: Clock) {
    self.impressionLogger = impressionLogger
    self.clock = clock
    self.viewport = CGRect.zero
    self.frames = []
    var contentToIndexPath = [Item: IndexPath]()
    for (sectionIndex, section) in sectionedArray.enumerated() {
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
  
  @objc public func setFrame(_ frame: CGRect, forContent content: Item) {
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
    var visibleItems = [IndexPath]()
    // TODO: For large content, binary or interpolation search.
    for (sectionIndex, section) in frames.enumerated() {
      for (frameIndex, frame) in section.enumerated() {
        let intersection = frame.intersection(viewport)
        let overlapRatio = intersection.area / frame.area
        if overlapRatio >= Self.visibilityThreshold {
          visibleItems.append(IndexPath(indexes: [sectionIndex, frameIndex]))
        }
      }
    }
    impressionLogger.collectionViewDidChangeContent(atIndexes: visibleItems)
  }
}

extension CGRect {
  var area: Float {
    return Float(width * height)
  }
}

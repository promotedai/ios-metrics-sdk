import CoreGraphics
import Foundation

@objc public class ScrollTracker: NSObject {
  
  private static let visibilityThreshold: Float = 0.5
  private static let updateThreshold: TimeInterval = 0.5
  
  private let impressionLogger: ImpressionLogger
  private let clock: Clock
  
  @objc public var viewportOrigin: CGPoint {
    didSet { maybeScheduleUpdateVisibilityTimer() }
  }
  @objc public var viewportSize: CGSize {
    didSet { maybeScheduleUpdateVisibilityTimer() }
  }

  private var frames: [[CGRect]]
  private var timer: ScheduledTimer?
  
  convenience init(singleSectionArray: [Item],
                   impressionLogger: ImpressionLogger,
                   clock: Clock) {
    self.init(multiSectionArray:[singleSectionArray],
              impressionLogger: impressionLogger,
              clock: clock)
  }
  
  init(multiSectionArray: [[Item]], impressionLogger: ImpressionLogger, clock: Clock) {
    self.impressionLogger = impressionLogger
    self.clock = clock
    self.viewportOrigin = CGPoint(x: 0, y: 0)
    self.viewportSize = CGSize(width: 0, height: 0)
    self.frames = []
    for array in multiSectionArray {
      self.frames.append([CGRect](repeating: CGRect.zero, count: array.count))
    }
    self.timer = nil
  }
  
  @objc public func setFrame(_ frame: CGRect, forContentAtIndex index: IndexPath) {
    index.setValue(frame, inArray: &frames)
  }
  
  private func maybeScheduleUpdateVisibilityTimer() {
    if timer != nil { return }
    timer = clock.schedule(timeInterval: Self.updateThreshold) { [weak self] _ in
      self?.updateVisibility()
    }
  }
  
  private func updateVisibility() {
    let viewportRect = CGRect(origin: viewportOrigin, size: viewportSize)
    var visibleItems = [IndexPath]()
    // TODO: For large content, binary or interpolation search.
    for (sectionIndex, section) in frames.enumerated() {
      for (frameIndex, frame) in section.enumerated() {
        let intersection = frame.intersection(viewportRect)
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

import CoreGraphics
import Foundation

public class ScrollTracker {
  
  private static let visibilityThreshold: Float = 0.5
  private static let updateThreshold: TimeInterval = 0.5
  
  private let clock: Clock
  private let metricsLogger: MetricsLogger
  
  private var impressionLogger: ImpressionLogger
  /*visibleForTesting*/ private(set) var contentToFrame: [Content: CGRect]
  private var timer: ScheduledTimer?
  
  /// Viewport of scroll view, based on scroll view's coord system.
  /// Under UIKit and React Native, this corresponds to the viewport
  /// of the scroll view as reported by scroll events.
  public var viewport: CGRect {
    didSet { maybeScheduleUpdateVisibilityTimer() }
  }

  init(metricsLogger: MetricsLogger, clock: Clock) {
    self.clock = clock
    self.metricsLogger = metricsLogger
    self.impressionLogger = ImpressionLogger(metricsLogger: metricsLogger,
                                             clock: clock)
    self.contentToFrame = [:]
    self.timer = nil
    self.viewport = CGRect.zero
  }
  
  public func clearContent() {
    contentToFrame.removeAll()
  }
  
  public func setFrame(_ frame: CGRect, forContent content: Content) {
    contentToFrame[content] = frame
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

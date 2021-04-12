import Foundation
import UIKit

/** Convenience methods for view controllers. */
public extension UIViewController {
  
  /// Returns the shared `MetricsLogger`.
  @objc var promotedLogger: MetricsLogger {
    return MetricsLoggerService.shared.metricsLogger
  }
  
  /// Returns the shared `MetricsLoggerService`.
  @objc var promotedLoggerService: MetricsLoggerService {
    return MetricsLoggerService.shared
  }
  
  /// Logs a view for self as a view controller.
  @objc func logPromotedViewForSelf() {
    self.promotedLogger.logView(viewController: self)
  }
  
  /// Logs a view for self as a view controller and given use case.
  @objc func logPromotedViewForSelf(useCase: UseCase) {
    self.promotedLogger.logView(viewController: self, useCase: useCase)
  }
}

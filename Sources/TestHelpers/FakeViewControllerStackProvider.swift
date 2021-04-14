import Foundation
import UIKit

@testable import PromotedAIMetricsSDK

public class FakeViewControllerStackProvider: ViewControllerStackProvider {
  public var viewControllers: [UIViewController] = []
  public func viewControllerStack() -> [UIViewController] {
    return viewControllers
  }
}

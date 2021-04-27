import Foundation
import UIKit

@testable import PromotedAIMetricsSDK

public class FakeUIState: UIState {
  public var viewControllers: [UIViewController] = []
  public func viewControllerStack() -> [UIViewController] {
    return viewControllers
  }
  public init() {}
}

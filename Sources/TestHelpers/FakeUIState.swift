import Foundation
import UIKit

@testable import PromotedAIMetricsSDK

class FakeUIState: UIState {
  var viewControllers: [UIViewController] = []
  func viewControllerStack() -> [UIViewController] {
    return viewControllers
  }
  init() {}
}

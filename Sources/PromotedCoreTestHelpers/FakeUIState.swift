import Foundation
import UIKit

@testable import PromotedCore

class FakeUIState: UIState {
  var viewControllers: [UIViewController] = []
  func viewControllerStack() -> [UIViewController] {
    return viewControllers
  }
  init() {}
}

import Foundation
import UIKit

@testable import PromotedCore

final class FakeUIState: UIState {

  var viewControllerStack: [UIViewController]
  var keyWindow: UIWindow?

  init() {
    viewControllerStack = []
    keyWindow = nil
  }
}

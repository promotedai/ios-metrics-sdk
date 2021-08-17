import Foundation
import UIKit

protocol UIState: AnyObject {
  func viewControllerStack() -> [UIViewController]
}

protocol UIStateSource {
  var uiState: UIState { get }
}

final class UIKitState: UIState {

  func viewControllerStack() -> [UIViewController] {
    guard let root = UIApplication.shared.keyWindow?.rootViewController else {
      return []
    }
    return Self.viewControllerStack(root: root)
  }

  static func viewControllerStack(root: UIViewController) -> [UIViewController] {
    var stack = [UIViewController]()
    var searchQueue = Deque<UIViewController>()
    var presentedViewController: UIViewController? = nil
    searchQueue.pushBack(root)
    while !searchQueue.isEmpty {
      let vc = searchQueue.popFront()
      stack.append(vc)
      if let nc = vc as? UINavigationController {
        // Last VC is handled on next iteration.
        stack.append(contentsOf: nc.viewControllers.dropLast())
        if let top = nc.topViewController {
          searchQueue.pushBack(top)
        }
      } else if let tc = vc as? UITabBarController,
                let selected = tc.selectedViewController {
        searchQueue.pushBack(selected)
      } else {
        searchQueue.pushBack(contentsOf: vc.children)
      }
      // Parents and children share the same value for
      // presentedViewController, and there can only be one
      // presentedViewController in a single presented batch.
      if let presented = vc.presentedViewController {
        presentedViewController = presented
      }
      // Presented VCs should appear at top of the stack, so put
      // them at the end of the search queue.
      if searchQueue.isEmpty && presentedViewController != nil {
        searchQueue.pushBack(presentedViewController!)
        presentedViewController = nil
      }
    }
    return stack
  }
}

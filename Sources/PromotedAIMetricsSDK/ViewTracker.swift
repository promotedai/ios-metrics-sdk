import Foundation

class ViewTracker {

  /// Representation of an entry in the view stack.
  enum Key: Equatable {
    case uiKit(viewController: ViewControllerType, useCase: UseCase? = nil)
    case reactNative(name: String, key: String? = nil, useCase: UseCase? = nil)
    case pending
  }
  
  /// Current state of view stack that can be translated to a View event.
  struct State {
    let name: String
    let useCase: UseCase?
    let viewID: String
  }

  fileprivate struct StackEntry: Equatable {
    let viewID: String
    let viewKey: Key
  }
  
  fileprivate typealias Stack = [StackEntry]

  fileprivate let viewIDProducer: IDProducer
  fileprivate var viewStack: Stack
  
  var viewID: String {
    return viewStack.last!.viewID
  }
  
  init(viewIDProducer: IDProducer) {
    self.viewIDProducer = viewIDProducer
    let entry = StackEntry(viewID: viewIDProducer.currentValue, viewKey: .pending)
    self.viewStack = [entry]
  }

  func trackView(key: Key) {
    switch key {
    case .uiKit(let viewController, let useCase):
      break
    case .reactNative(let name, let key, let useCase):
      break
    case .pending:
      assertionFailure("Don't log a key of type pending")
    }
  }
  
  func state() -> State? {
    let previousStack = viewStack
    viewStack = updatedViewStack(previousStack: previousStack)
    if previousStack.last != viewStack.last,
       let newTop = viewStack.last {
      switch newTop.viewKey {
      case .uiKit(let viewController, let useCase):
        let name = loggingNameFor(viewController: viewController)
        return State(name: name, useCase: useCase, viewID: newTop.viewID)
      case .reactNative(let name, _, let useCase):
        return State(name: name, useCase: useCase, viewID: newTop.viewID)
      case .pending:
        return State(name: "Unnamed", useCase: nil, viewID: newTop.viewID)
      }
    }
    return nil
  }
  
  fileprivate func updatedViewStack(previousStack: Stack) -> Stack {
    assertionFailure("Do not instantiate ViewTracker")
    return []
  }
  
  private func loggingNameFor(viewController: ViewControllerType) -> String {
    let className = String(describing: type(of: viewController))
    let loggingName = className.replacingOccurrences(of:"ViewController", with: "")
    if loggingName.isEmpty { return "Unnamed" }
    return loggingName
  }
}

#if canImport(UIKit)
import UIKit
#endif

// MARK: - UIKit
class UIKitViewTracker: ViewTracker {

  private static func viewControllerStack() -> [ViewControllerType] {
    var stack = [ViewControllerType]()
    #if canImport(UIKit)
    var vc = UIApplication.shared.keyWindow?.rootViewController
    while let viewController = vc {
      if let presented = viewController.presentedViewController {
        stack.append(viewController)
        vc = presented
      } else if let nc = vc as? UINavigationController {
        stack.append(contentsOf: nc.viewControllers)
        vc = nc.topViewController
      } else if let tc = vc as? UITabBarController {
        stack.append(viewController)
        vc = tc.selectedViewController
      } else {
        stack.append(viewController)
      }
    }
    #endif
    return stack
  }

  fileprivate override func updatedViewStack(previousStack: Stack) -> Stack {
    let viewControllerStack = Self.viewControllerStack()
    let newStack = viewControllerStack.map { vc -> StackEntry in
      let entry = previousStack.first { e in
        if case Key.uiKit(let stackVC, _) = e.viewKey { return vc === stackVC }
        return false
      }
      if let entry = entry { return entry }
      return StackEntry(viewID: viewIDProducer.nextValue(),
                        viewKey: .uiKit(viewController: vc))
    }
    return newStack
  }
}

// MARK: - React Native
public class ReactNativeViewTracker {

  public func routeDidChange(name: String, key: String, useCase: UseCase? = nil) {
    if let index = routeKeyStack.firstIndex(of: key) {
      let removalCount = routeKeyStack.count - 1 - index
      guard removalCount > 0 else {
        assertionFailure("New route key identical to previous: \(key)")
        return
      }
      routeNameStack.removeLast(removalCount)
      routeKeyStack.removeLast(removalCount)
    } else {
      routeNameStack.append(name)
      routeKeyStack.append(key)
    }
  }
}

import Foundation
import UIKit

// MARK: - ViewTracker
class ViewTracker {

  /// Representation of an entry in the view stack.
  enum Key: Equatable {
    case uiKit(viewController: UIViewController)
    case reactNative(routeName: String, routeKey: String)
  }
  
  /// Current state of view stack that can be translated to a View event.
  struct State: Equatable {
    let viewKey: Key
    let useCase: UseCase?
    let viewID: String
    
    var name: String {
      switch viewKey {
      case .uiKit(let viewController):
        return viewController.promotedViewLoggingName
      case .reactNative(let name, _):
        return name
      }
    }
  }
  
  fileprivate typealias Stack = [State]

  private let viewIDProducer: IDProducer
  private var viewStack: Stack
  private let stackProvider: ViewControllerStackProvider
  private let isReactNativeHint: Bool
  
  var viewID: String {
    return viewStack.top?.viewID ?? viewIDProducer.currentValue
  }
  
  init(idMap: IDMap,
       stackProvider: ViewControllerStackProvider = UIKitViewControllerStackProvider()) {
    self.viewIDProducer = IDProducer { idMap.viewID() }
    self.viewStack = []
    self.stackProvider = stackProvider
    self.isReactNativeHint = (NSClassFromString("PromotedMetricsModule") != nil)
  }

  /// Manually tracks a view, then returns a `State` if this call
  /// caused the state of the view stack to change since the last
  /// call to `trackView(key:)` or `updateState()`.
  func trackView(key: Key, useCase: UseCase? = nil) -> State? {
    defer { print("***** track \(viewStack)") }
    if key == viewStack.top?.viewKey {
      return nil
    }
    if viewStack.popTo(key: key) {
      return viewStack.top!
    }
    let viewID = viewIDProducer.nextValue()
    let top = State(viewKey: key, useCase: useCase, viewID: viewID)
    viewStack.push(top)
    return top
  }

  /// Returns `State` if it has changed since the last call to
  /// `trackView(key:)` or `updateState()`.
  func updateState() -> State? {
    defer { print("***** update \(viewStack)") }
    let previousStack = viewStack
    viewStack = updatedViewStack(previousStack: previousStack)
    let newTop = viewStack.top
    if previousStack.top == newTop { return nil }
    return newTop
  }

  /// Removes all tracked views and resets to original state.
  func reset() {
    viewStack.removeAll()
  }

  private func updatedViewStack(previousStack: Stack) -> Stack {
    // Use `isReactNativeHint` only to break ties in the case
    // where the stack is empty.
    if viewStack.isEmpty && isReactNativeHint {
      return previousStack
    }

    // Must have UIKit view key at stack top.
    guard let key = viewStack.top?.viewKey, case Key.uiKit(_) = key else {
      return previousStack
    }

    // Regenerate stack, joining against the previous stack.
    let viewControllerStack = stackProvider.viewControllerStack()
    let newStack = viewControllerStack.map { vc -> State in
      if let entry = previousStack.first(matching: vc) {
        return entry
      }
      // No entry in previous stack. We've never seen this VC before.
      // Don't know the use case for it.
      let viewKey = Key.uiKit(viewController: vc)
      let viewID = viewIDProducer.nextValue()
      return State(viewKey: viewKey, useCase: nil, viewID: viewID)
    }
    return newStack
  }
}

extension ViewTracker.Key: CustomDebugStringConvertible {
  var debugDescription: String {
    switch self {
    case .uiKit(let viewController):
      return "UIKit(\(viewController.promotedViewLoggingName))"
    case .reactNative(let routeName, _):
      return "ReactNative(\(routeName))"
    }
  }
}

extension ViewTracker.State: CustomDebugStringConvertible {
  var debugDescription: String {
    return "\(viewKey.debugDescription)-\(viewID.suffix(5))"
  }
}

// MARK: - Stack
fileprivate extension ViewTracker.Stack {
  var top: ViewTracker.State? { return last }
  
  mutating func push(_ entry: ViewTracker.State) {
    append(entry)
  }

  func first(matching viewController: UIViewController) -> ViewTracker.State? {
    if let index = self.firstIndex(matching: viewController) {
      return self[index]
    }
    return nil
  }

  func firstIndex(matching viewController: UIViewController) -> Int? {
    return self.firstIndex { e in
      if case ViewTracker.Key.uiKit(let vc) = e.viewKey {
        return viewController == vc
      }
      return false
    }
  }

  func firstIndex(matching routeKey: String) -> Int? {
    return self.firstIndex { e in
      if case ViewTracker.Key.reactNative(_, let k) = e.viewKey {
        return k == routeKey
      }
      return false
    }
  }

  /// Pops off the stack until given index is at the top.
  ///
  /// - Postcondition: !isEmpty
  mutating func popTo(index: Int) -> Bool {
    let removalCount = count - 1 - index
    guard (removalCount > 0) && (removalCount < count) else { return false }
    removeLast(removalCount)
    return true
  }

  mutating func popTo(routeKey: String) -> Bool {
    if let index = firstIndex(matching: routeKey) {
      return popTo(index: index)
    }
    return false
  }

  mutating func popTo(viewController: UIViewController) -> Bool {
    if let index = firstIndex(matching: viewController) {
      return popTo(index: index)
    }
    return false
  }
  
  mutating func popTo(key: ViewTracker.Key) -> Bool {
    switch key {
    case .uiKit(let viewController):
      return popTo(viewController: viewController)
    case .reactNative(_, let routeKey):
      return popTo(routeKey: routeKey)
    }
  }
}

// MARK: - UIKit
protocol ViewControllerStackProvider: class {
  func viewControllerStack() -> [UIViewController]
}

@objc protocol ContainerViewController: class {
  @objc optional func promotedContentViewController() -> UIViewController?
}

class UIKitViewControllerStackProvider: ViewControllerStackProvider {
  func viewControllerStack() -> [UIViewController] {
    let contentSelector = #selector(ContainerViewController.promotedContentViewController)
    var stack = [UIViewController]()
    var optionalVC = UIApplication.shared.keyWindow?.rootViewController
    while let vc = optionalVC {
      stack.append(vc)
      // Check for composite VCs and append their content.
      optionalVC = nil
      if let nc = vc as? UINavigationController {
        // Last one is handled on next iteration.
        stack.append(contentsOf: nc.viewControllers.dropLast())
        optionalVC = nc.topViewController
      } else if let tc = vc as? UITabBarController,
                let selectedViewController = tc.selectedViewController {
        optionalVC = selectedViewController
      } else if vc.responds(to: contentSelector) {
        let unmanaged = vc.perform(contentSelector)
        if let contentVC = unmanaged?.takeUnretainedValue() as? UIViewController {
          optionalVC = contentVC
        }
      }
      if let presented = vc.presentedViewController {
        if let intermediary = optionalVC {
          stack.append(intermediary)
        }
        optionalVC = presented
      }
    }
    return stack
  }
}

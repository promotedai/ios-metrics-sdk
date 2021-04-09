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

  func trackView(key: Key) -> State? {
    switch key {
    case .uiKit(let viewController, let useCase):
      break
    case .reactNative(let name, let key, let useCase):
      break
    case .pending:
      assertionFailure("Don't log a key of type pending")
    }
    return nil
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

fileprivate extension ViewTracker.Stack {

  func first(matching viewController: ViewControllerType) -> ViewTracker.StackEntry? {
    if let index = self.firstIndex(matching: viewController) {
      return self[index]
    }
    return nil
  }

  func firstIndex(matching viewController: ViewControllerType) -> Int? {
    return self.firstIndex { e in
      if case ViewTracker.Key.uiKit(let vc, _) = e.viewKey {
        return viewController == vc
      }
      return false
    }
  }

  func firstIndex(matching key: String) -> Int? {
    return self.firstIndex { e in
      if case ViewTracker.Key.reactNative(_, let k, _) = e.viewKey {
        return k == key
      }
      return false
    }
  }

  mutating func popTo(index: Int) -> Bool {
    let removalCount = count - 1 - index
    guard removalCount > 0 else { return false }
    removeLast(removalCount)
    return true
  }

  mutating func popTo(reactNativeKey: String) -> Bool {
    if let index = firstIndex(matching: reactNativeKey) {
      return popTo(index: index)
    }
    return false
  }

  mutating func popTo(viewController: ViewControllerType) -> Bool {
    if let index = firstIndex(matching: viewController) {
      return popTo(index: index)
    }
    return false
  }
  
  mutating func popTo(key: ViewTracker.Key) -> Bool {
    switch key {
    case .uiKit(let viewController, _):
      return popTo(viewController: viewController)
    case .reactNative(_, let reactNativeKey, _):
      if let k = reactNativeKey { return popTo(reactNativeKey: k) }
    case .pending:
      return false
    }
    return false
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
      if let entry = previousStack.first(matching: vc) {
        return entry
      }
      return StackEntry(viewID: viewIDProducer.nextValue(),
                        viewKey: .uiKit(viewController: vc))
    }
    return newStack
  }
}

// MARK: - React Native
class ReactNativeViewTracker: ViewTracker {

  public func routeDidChange(name: String, key: String, useCase: UseCase? = nil) {
    if viewStack.popTo(reactNativeKey: key) {
      return
    }
    let key = Key.reactNative(name: name, key: key, useCase: useCase)
    let entry = StackEntry(viewID: viewIDProducer.nextValue(), viewKey: key)
    viewStack.append(entry)
  }
}

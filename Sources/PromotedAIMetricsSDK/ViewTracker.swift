import Foundation

fileprivate func LoggingNameFor(viewController: ViewControllerType) -> String {
  let className = String(describing: type(of: viewController))
  let loggingName = className.replacingOccurrences(of:"ViewController", with: "")
  if loggingName.isEmpty { return "Unnamed" }
  return loggingName
}

// MARK: - ViewTracker
public class ViewTracker {

  /// Representation of an entry in the view stack.
  public enum Key: Equatable {
    case uiKit(viewController: ViewControllerType, useCase: UseCase? = nil)
    case reactNative(name: String, key: String? = nil, useCase: UseCase? = nil)
  }
  
  /// Current state of view stack that can be translated to a View event.
  public struct State {
    let name: String
    let useCase: UseCase?
    let viewID: String
    
    fileprivate init(stackEntry: StackEntry) {
      switch stackEntry.viewKey {
      case .uiKit(let viewController, let useCase):
        self.name = LoggingNameFor(viewController: viewController)
        self.useCase = useCase
      case .reactNative(let name, _, let useCase):
        self.name = name
        self.useCase = useCase
      }
      self.viewID = stackEntry.viewID
    }
  }

  fileprivate struct StackEntry: Equatable {
    let viewKey: Key
    let viewID: String
  }
  
  fileprivate typealias Stack = [StackEntry]

  fileprivate let viewIDProducer: IDProducer
  fileprivate var viewStack: Stack
  
  var viewID: String {
    return viewStack.top?.viewID ?? viewIDProducer.currentValue
  }
  
  init(viewIDProducer: IDProducer) {
    self.viewIDProducer = viewIDProducer
    self.viewStack = []
  }

  /// Manually tracks a view, then returns a `State` if this call
  /// caused the state of the view stack to change since the last
  /// call to `trackView(key:)` or `updateState()`.
  func trackView(key: Key) -> State? {
    if key == viewStack.top?.viewKey {
      return nil
    }
    if viewStack.popTo(key: key) {
      return State(stackEntry: viewStack.top!)
    }
    let top = StackEntry(viewKey: key, viewID: viewIDProducer.nextValue())
    viewStack.push(top)
    return State(stackEntry: top)
  }

  /// Returns `State` if it has changed since the last call to
  /// `trackView(key:)` or `updateState()`.
  func updateState() -> State? {
    let previousStack = viewStack
    viewStack = updatedViewStack(previousStack: previousStack)
    guard let newTop = viewStack.top else { return nil }
    if previousStack.top == newTop { return nil }
    return State(stackEntry: newTop)
  }

  fileprivate func updatedViewStack(previousStack: Stack) -> Stack {
    assertionFailure("Don't instantiate ViewTracker")
    return previousStack
  }
}

// MARK: - Stack
fileprivate extension ViewTracker.Stack {
  var top: ViewTracker.StackEntry? { return last }
  
  mutating func push(_ entry: ViewTracker.StackEntry) {
    append(entry)
  }

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

  /// Pops off the stack until given index is at the top.
  ///
  /// - Postcondition: !isEmpty
  mutating func popTo(index: Int) -> Bool {
    let removalCount = count - 1 - index
    guard (removalCount > 0) && (removalCount < count) else { return false }
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
    }
    return false
  }
}

#if canImport(UIKit)
import UIKit
#endif

// MARK: - UIKit
public class UIKitViewTracker: ViewTracker {

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
        break
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
      return StackEntry(viewKey: .uiKit(viewController: vc),
                        viewID: viewIDProducer.nextValue())
    }
    return newStack
  }
}

// MARK: - React Native
public class ReactNativeViewTracker: ViewTracker {

  public func routeDidChange(name: String, key: String, useCase: UseCase? = nil) {
    if viewStack.popTo(reactNativeKey: key) {
      return
    }
    let key = Key.reactNative(name: name, key: key, useCase: useCase)
    let entry = StackEntry(viewKey: key, viewID: viewIDProducer.nextValue())
    viewStack.push(entry)
  }
  
  fileprivate override func updatedViewStack(previousStack: Stack) -> Stack {
    return previousStack
  }
}

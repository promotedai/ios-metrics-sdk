import Foundation

func LoggingNameFor(viewController: ViewControllerType) -> String {
  let className = String(describing: type(of: viewController))
  let loggingName = className.replacingOccurrences(of:"ViewController", with: "")
  if loggingName.isEmpty { return "Unnamed" }
  return loggingName
}

// MARK: - ViewTracker
class ViewTracker {

  /// Representation of an entry in the view stack.
  enum Key: Equatable {
    case uiKit(viewController: ViewControllerType)
    case reactNative(name: String, key: String)
  }
  
  /// Current state of view stack that can be translated to a View event.
  struct State: Equatable {
    let viewKey: Key
    let useCase: UseCase?
    let viewID: String
    
    var name: String {
      switch viewKey {
      case .uiKit(let viewController):
        return LoggingNameFor(viewController: viewController)
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
    let previousStack = viewStack
    viewStack = updatedViewStack(previousStack: previousStack)
    let newTop = viewStack.top
    if previousStack.top == newTop { return nil }
    return newTop
  }

  private func updatedViewStack(previousStack: Stack) -> Stack {
    if isReactNativeHint { return previousStack }

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

// MARK: - Stack
fileprivate extension ViewTracker.Stack {
  var top: ViewTracker.State? { return last }
  
  mutating func push(_ entry: ViewTracker.State) {
    append(entry)
  }

  func first(matching viewController: ViewControllerType) -> ViewTracker.State? {
    if let index = self.firstIndex(matching: viewController) {
      return self[index]
    }
    return nil
  }

  func firstIndex(matching viewController: ViewControllerType) -> Int? {
    return self.firstIndex { e in
      if case ViewTracker.Key.uiKit(let vc) = e.viewKey {
        return viewController == vc
      }
      return false
    }
  }

  func firstIndex(matching key: String) -> Int? {
    return self.firstIndex { e in
      if case ViewTracker.Key.reactNative(_, let k) = e.viewKey {
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
    case .uiKit(let viewController):
      return popTo(viewController: viewController)
    case .reactNative(_, let reactNativeKey):
      return popTo(reactNativeKey: reactNativeKey)
    }
  }
}

// MARK: - UIKit
#if canImport(UIKit)
import UIKit
#endif

protocol ViewControllerStackProvider: class {
  func viewControllerStack() -> [ViewControllerType]
}

class UIKitViewControllerStackProvider: ViewControllerStackProvider {
  func viewControllerStack() -> [ViewControllerType] {
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
}

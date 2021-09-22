import Foundation
import UIKit

// MARK: - ViewTracker
final class ViewTracker {

  /// Representation of an entry in the view stack.
  // TODO(yu-hong): Remove this enum and simplify this class
  // as part of auto view tracking for UIKit.
  enum Key: Equatable {
    case uiKit(viewController: UIViewController)
  }
  
  /// Current state of view stack that can be translated to a View event.
  struct State: Equatable {
    let viewKey: Key
    let useCase: UseCase?

    var name: String {
      switch viewKey {
      case .uiKit(let viewController):
        return viewController.promotedViewLoggingName
      }
    }
  }

  fileprivate typealias Stack = [State]

  private let viewIDProducer: IDProducer
  private var viewStack: Stack
  private let uiState: UIState
  private let isReactNativeHint: Bool

  var id: IDSequence { viewIDProducer }

  typealias Deps = IDMapSource & UIStateSource

  init(deps: Deps) {
    let idMap = deps.idMap
    self.viewIDProducer = IDProducer { idMap.viewID() }
    self.viewStack = []
    self.uiState = deps.uiState
    self.isReactNativeHint = (NSClassFromString("PromotedMetricsModule") != nil)
  }

  /// Manually tracks a view, then returns a `State` if this call
  /// caused the state of the view stack to change since the last
  /// call to `trackView(key:)` or `updateState()`.
  func trackView(key: Key, useCase: UseCase? = nil) -> State? {
    if key == viewStack.top?.viewKey {
      return nil
    }
    viewIDProducer.advance()
    if viewStack.popTo(key: key) {
      return viewStack.top!
    }
    let top = State(viewKey: key, useCase: useCase)
    viewStack.push(top)
    return top
  }

  /// Returns `State` if it has changed since the last call to
  /// `trackView(key:)` or `updateState()`.
  func updateState() -> State? {
    let previousStack = viewStack
    viewStack = updateViewStack(previousStack: previousStack)
    let newTop = viewStack.top
    if previousStack.top == newTop { return nil }
    viewIDProducer.advance()
    return newTop
  }

  /// Removes all tracked views and resets to original state.
  func reset() {
    viewStack.removeAll()
    viewIDProducer.reset()
  }

  private func updateViewStack(previousStack: Stack) -> Stack {
    // Use `isReactNativeHint` only to break ties in the case
    // where the stack is empty.
    if viewStack.isEmpty {
      return previousStack
    }

    // Must have UIKit view key at stack top.
    guard let key = viewStack.top?.viewKey, case Key.uiKit(_) = key else {
      return previousStack
    }

    // Regenerate stack, including only VCs that were explicitly
    // logged. These are the VCs in the previous stack.
    let viewControllerStack = uiState.viewControllerStack()
    let newStack = viewControllerStack.compactMap {
      previousStack.first(matching: $0)
    }
    return newStack
  }
}

protocol ViewTrackerSource {
  var viewTracker: ViewTracker { get }
}

extension ViewTracker {
  var viewStackForTesting: [State] { viewStack }
}

extension ViewTracker.Key: CustomDebugStringConvertible {
  var debugDescription: String {
    switch self {
    case .uiKit(let viewController):
      return "UIKit(\(viewController.promotedViewLoggingName))"
    }
  }
}

extension ViewTracker.State: CustomDebugStringConvertible {
  var debugDescription: String { viewKey.debugDescription }
}

// MARK: - Stack
fileprivate extension ViewTracker.Stack {
  var top: ViewTracker.State? { last }
  
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
    self.firstIndex { e in
      if case ViewTracker.Key.uiKit(let vc) = e.viewKey {
        return viewController == vc
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
    }
  }
}

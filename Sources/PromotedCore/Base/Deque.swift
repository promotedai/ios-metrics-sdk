import Foundation

/**
 Double-ended queue with bounded size.
 Can be used as a fixed-size buffer.

 Swift 5.3 does not offer a built-in bounded buffer.
 This class currently backed by an Array, which has O(n)
 complexity for popFront operations, but we could
 replace this easily if we need better performance.

 Some alternatives to creating this struct, and why we
 didn't choose them:

 1. Use Swift Collections `Deque`. While it's a robust
    implementation, Swift Collections doesn't support
    CocoaPods, which many of our clients use.
 2. Use another `Deque` implementation from the internet.
    It's hard to find an implementation that supports
    both Swift PM and CocoaPods. Also, security concerns
    over using third-party code.
 3. Stick with built-in `Array` type. This would require
    us to duplicate the bounding logic in many places, and
    it's too easy for users to get this wrong. You can't
    subclass Swift's `Array` because it's a struct and not
    a class.
 4. Use Objective C's `NSCache` or similar data structure.
    This would only work with Objective C-compatible objects,
    and not Swift structs or primitive types, which means
    that it can't hold Swift Protobufs (they are structs).
 */
struct Deque<Element> {
  var maximumSize: Int? {
    didSet {
      if let max = maximumSize, max <= 0 {
        maximumSize = nil
      } else {
        trim()
      }
    }
  }
  fileprivate(set) var values: [Element]

  init(maximumSize: Int? = nil) {
    self.maximumSize = maximumSize
    self.values = []
  }
}

extension Deque: ExpressibleByArrayLiteral {

  init(arrayLiteral elements: Element...) {
    self.maximumSize = nil
    self.values = Array(elements)
  }
}

extension Deque {

  var count: Int { values.count }

  var isEmpty: Bool { values.isEmpty }

  subscript(position: Int) -> Element {
    get { values[position] }
    set { values[position] = newValue }
  }
}

extension Deque {

  mutating func pushBack(_ value: Element) {
    values.append(value)
    trim()
  }

  mutating func pushBack<C>(contentsOf newElements: C) where C.Element == Element, C.Index == Int, C: Collection {
    values.append(contentsOf: newElements)
    trim()
  }

  mutating func pushFront(_ value: Element) {
    values.insert(value, at: 0)
    trim(location: .back)
  }

  mutating func pushFront<C>(contentsOf newElements: C) where C.Element == Element, C: Collection {
    values.insert(contentsOf: newElements, at: 0)
    trim(location: .back)
  }

  @discardableResult mutating func popBack() -> Element {
    return values.removeLast()
  }

  mutating func popBack(_ k: Int) {
    values.removeLast(k)
  }

  @discardableResult mutating func popFront() -> Element {
    return values.removeFirst()
  }

  mutating func popFront(_ k: Int) {
    values.removeFirst(k)
  }

  mutating func removeAll() {
    values.removeAll()
  }
}

fileprivate extension Deque {

  enum TrimLocation {
    case front
    case back
  }

  mutating func trim(location: TrimLocation = .front) {
    guard let max = maximumSize else { return }
    let excess = values.count - max
    if excess > 0 {
      switch location {
      case .front:
        popFront(excess)
      case .back:
        popBack(excess)
      }
    }
  }
}

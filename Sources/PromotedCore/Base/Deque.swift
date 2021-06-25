import Foundation

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
    let excess = max - values.count
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

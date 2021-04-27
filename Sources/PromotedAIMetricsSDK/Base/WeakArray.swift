import Foundation

protocol AnyWeak {
  associatedtype T
  var value: T? { get set }
}

struct Weak<T>: AnyWeak {
  private weak var wrapped: AnyObject?
  var value: T? {
    get { wrapped as? T }
    set { wrapped = newValue as AnyObject }
  }
  init(_ value: T) {
    self.value = value
  }
}

typealias WeakArray<T> = [Weak<T>]

extension Array {
  mutating func append<T>(_ element: T) where Element == Weak<T> {
    compact()
    append(Weak(element))
  }

  mutating func removeAll<T>(identicalTo element: T) where Element == Weak<T> {
    compact()
    removeAll { ($0.value as AnyObject) === (element as AnyObject) }
  }

  typealias Visitor<T> = (T) -> Void
  func forEach<T>(_ visitor: Visitor<T>) where Element == Weak<T> {
    for object in self {
      visitor(object.value!)
    }
  }
}

extension Array where Element: AnyWeak {
  mutating func compact() {
    removeAll { $0.value == nil }
  }
}

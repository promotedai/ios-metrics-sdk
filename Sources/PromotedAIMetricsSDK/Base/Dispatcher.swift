import Foundation

class Dispatcher<T> {
  fileprivate struct WeakReference {
    fileprivate private(set) weak var object: AnyObject?
    fileprivate init(_ object: AnyObject) {
      self.object = object
    }
  }

  fileprivate typealias WeakArray = [WeakReference]
  private var listeners: WeakArray
  
  init() {
    listeners = []
  }

  func addListener(_ listener: T) {
    listeners.append(WeakReference(listener as AnyObject))
    listeners.removeAll { $0.object == nil }
  }

  func removeListener(_ listener: T) {
    listeners.removeAll {
      $0.object == nil || $0.object === (listener as AnyObject)
    }
  }

  typealias Visitor = (T) -> Void

  func iterate(_ visitor: Visitor) {
    listeners.removeAll { $0.object == nil }
    for weakObject in listeners {
      visitor(weakObject.object! as! T)
    }
  }
}

fileprivate extension Array where Element == Dispatcher<Any>.WeakReference {
  mutating func compact() {
    removeAll { $0.object == nil }
  }
}

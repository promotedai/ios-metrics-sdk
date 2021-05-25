import Foundation

/**
 Allows us to read values for session IDs before starting
 a session and keep those IDs consistent when the session
 does start.
 */
final class IDProducer {

  typealias Producer = () -> String
  
  private let initialValueProducer: Producer
  private let nextValueProducer: Producer
  private(set) var hasAdvancedFromInitialValue: Bool
  lazy var currentValue: String = { initialValueProducer() } ()
  
  convenience init(producer: @escaping Producer) {
    self.init(initialValueProducer: producer,
              nextValueProducer: producer)
  }

  init(initialValueProducer: @escaping Producer,
       nextValueProducer: @escaping Producer) {
    self.initialValueProducer = initialValueProducer
    self.nextValueProducer = nextValueProducer
    self.hasAdvancedFromInitialValue = false
  }

  @discardableResult func nextValue() -> String {
    if !hasAdvancedFromInitialValue {
      hasAdvancedFromInitialValue = true
      return currentValue
    }
    currentValue = nextValueProducer()
    return currentValue
  }
}

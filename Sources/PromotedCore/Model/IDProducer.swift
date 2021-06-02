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
  private var hasAdvancedFromInitialValue: Bool

  /// Reads the current ID from this producer.
  /// If `nextValue()` has never been called, returns the
  /// initial value. Use this to read the pending initial
  /// ID before the corresponding ancestor event has been
  /// logged.
  lazy var currentValue: String = initialValueProducer() {
    didSet { hasAdvancedFromInitialValue = true }
  }

  /// Reads the current ID for use as an ancestor ID
  /// in an event message.
  /// If `nextValue()` has never been called, return `nil`.
  var currentValueForAncestorID: String? {
    hasAdvancedFromInitialValue ? currentValue : nil
  }

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

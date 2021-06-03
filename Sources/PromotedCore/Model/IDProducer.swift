import Foundation

/**
 Manages values for ancestor ID sequences.

 Allows clients to read pending ancestor IDs before starting
 a session and keep those IDs consistent when the session
 does start.

 Clients can also assign custom values to the ID.
 */
final class IDProducer {

  typealias Producer = () -> String

  private let initialValueProducer: Producer
  private let nextValueProducer: Producer
  private var valueHasBeenSet: Bool

  /// Current ID from this producer.
  /// - If `nextValue()` has never been called, returns the
  ///   initial value. Use this to read the pending initial
  ///   ID before the corresponding ancestor event has been
  ///   logged.
  /// - If assigned an external value, returns that external
  ///   value.
  /// - Otherwise, this value is managed internally by this
  ///   class and updated when `nextValue()` is called.
  lazy var currentValue: String = initialValueProducer() {
    didSet { valueHasBeenSet = true }
  }

  /// Reads the current ID for use as an ancestor ID
  /// in an event message.
  /// If `nextValue()` has never been called, return `nil`.
  var currentValueAsAncestorID: String? {
    valueHasBeenSet ? currentValue : nil
  }

  /// Uses given producer in all cases.
  convenience init(producer: @escaping Producer) {
    self.init(initialValueProducer: producer,
              nextValueProducer: producer)
  }

  /// Uses producers as follows:
  /// - Parameters:
  ///   - initialValueProducer: Used when either:
  ///     1. Initializing `currentValue` lazily for the
  ///        first time, or
  ///     2. Re-initializing `currentValue` after a call
  ///        to `reset()`.
  ///   - nextValueProducer: Used when `nextValue()` is
  ///     called.
  init(initialValueProducer: @escaping Producer,
       nextValueProducer: @escaping Producer) {
    self.initialValueProducer = initialValueProducer
    self.nextValueProducer = nextValueProducer
    self.valueHasBeenSet = false
  }

  @discardableResult func nextValue() -> String {
    if !valueHasBeenSet {
      valueHasBeenSet = true
      return currentValue
    }
    currentValue = nextValueProducer()
    return currentValue
  }

  func reset() {
    valueHasBeenSet = false
    currentValue = initialValueProducer()
  }
}

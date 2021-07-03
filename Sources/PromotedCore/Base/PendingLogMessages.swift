import Foundation

/**
 Queues log messages until after `ClientConfig` is available.
 If you need to log messages in any of the `ClientConfig`
 classes, use this. The messages contained in here are
 flushed immediately after the config is loaded.
 */
public struct PendingLogMessages {

  public enum Visibility {
    case `public`
    case `private`
  }
  typealias LogLevel = ClientConfig.OSLogLevel

  struct PendingMessage {
    let message: String
    let visibility: Visibility
    let level: LogLevel
  }
  fileprivate(set) var messages: [PendingMessage] = []

  public init() {}
}

public extension PendingLogMessages {
  mutating func error(_ message: String, visibility: Visibility = .private) {
    append(message, visibility, .error)
  }

  mutating func warning(_ message: String, visibility: Visibility = .private) {
    append(message, visibility, .warning)
  }

  mutating func info(_ message: String, visibility: Visibility = .private) {
    append(message, visibility, .info)
  }

  mutating func debug(_ message: String, visibility: Visibility = .private) {
    append(message, visibility, .debug)
  }

  internal mutating func append(
    _ message: String,
    _ visibility: Visibility,
    _ level: LogLevel
  ) {
    messages.append(
      PendingMessage(message: message, visibility: visibility, level: level)
    )
  }
}

public func + (
  a: PendingLogMessages, b: PendingLogMessages
) -> PendingLogMessages {
  var result = PendingLogMessages()
  result.messages = a.messages + b.messages
  return result
}

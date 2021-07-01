import Foundation

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
  private(set) var messages: [PendingMessage] = []

  public init() {}
}

public extension PendingLogMessages {
  mutating func error(
    _ message: String,
    visibility: Visibility = .private
  ) {
    append(message, visibility, .error)
  }

  mutating func warning(
    _ message: String,
    visibility: Visibility = .private
  ) {
    append(message, visibility, .warning)
  }

  mutating func info(
    _ message: String,
    visibility: Visibility = .private
  ) {
    append(message, visibility, .info)
  }

  mutating func debug(
    _ message: String,
    visibility: Visibility = .private
  ) {
    append(message, visibility, .debug)
  }

  internal mutating func append(
    _ message: String,
    _ visibility: Visibility,
    _ level: LogLevel
  ) {
    messages.append(
      PendingMessage(
        message: message,
        visibility: visibility,
        level: level
      )
    )
  }
}

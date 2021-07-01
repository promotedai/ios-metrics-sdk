import Foundation

public struct PendingLogMessages {

  public enum Visibility {
    case `public`
    case `private`
  }

  private(set) var errors: [(String, Visibility)] = []

  private(set) var warnings: [(String, Visibility)] = []

  private(set) var infos: [(String, Visibility)] = []

  private(set) var debugs: [(String, Visibility)] = []

  public init() {}
}

public extension PendingLogMessages {
  mutating func error(
    _ message: String,
    visibility: Visibility = .private
  ) {
    errors.append((message, visibility))
  }

  mutating func warning(
    _ message: String,
    visibility: Visibility = .private
  ) {
    warnings.append((message, visibility))
  }

  mutating func info(
    _ message: String,
    visibility: Visibility = .private
  ) {
    infos.append((message, visibility))
  }

  mutating func debug(
    _ message: String,
    visibility: Visibility = .private
  ) {
    debugs.append((message, visibility))
  }
}

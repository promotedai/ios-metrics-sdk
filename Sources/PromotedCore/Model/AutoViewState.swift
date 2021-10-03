import Foundation

/** AutoView-related state information. */
public struct AutoViewState {

  /// ID for associted AutoView.
  public var autoViewID: String?

  /// Whether this view may not be topmost.
  public var hasSuperimposedViews: Bool?

  public init(
    autoViewID: String?,
    hasSuperimposedViews: Bool?
  ) {
    self.autoViewID = autoViewID
    self.hasSuperimposedViews = hasSuperimposedViews
  }

  /// Empty state to use when state is unavailable.
  public static let empty = AutoViewState(
    autoViewID: nil,
    hasSuperimposedViews: nil
  )
}

extension AutoViewState: CustomDebugStringConvertible {
  public var debugDescription: String {
    return "(" +
      "autoViewID: \(autoViewID ?? "nil") " +
      "hasSuperimposedViews: \(hasSuperimposedViews ?? false)" +
    ")"
  }
}

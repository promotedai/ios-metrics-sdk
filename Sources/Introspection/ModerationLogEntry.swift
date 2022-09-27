import Foundation

public struct ModerationLogEntry {
  public let content: Content
  public let action: ModerationAction
  public let scope: ModerationScope
  public let scopeFilter: String?
  public let rankChangePercent: Int?
  public let date: Date
  public let image: UIImage?
}

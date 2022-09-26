import Foundation

public struct ModerationLogEntry {
  let content: Content
  let action: ModerationViewController.ModerationAction
  let scope: ModerationViewController.ModerationScope
  let scopeFilter: String?
  let rankChangePercent: Int?
  let date: Date
}

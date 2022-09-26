import Foundation
import UIKit

public class ModerationLogViewController: UIViewController {

  public struct LogEntry {
    let action: ModerationViewController.ModerationAction
    let scope: ModerationViewController.ModerationScope
    let rankChangePercent: Int
  }

  private let contents: [LogEntry]

  public init(contents: [LogEntry]) {
    self.contents = contents
    super.init(nibName: nil, bundle: nil)
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  public override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    
  }
}

import Foundation
import UIKit

@available(iOS 13, *)
public protocol ModerationLogViewControllerDelegate: AnyObject {

}

@available(iOS 13.0, *)
public class ModerationLogViewController: UIViewController {

  public struct LogEntry {
    let content: Content
    let action: ModerationViewController.ModerationAction
    let scope: ModerationViewController.ModerationScope
    let scopeFilter: String?
    let rankChangePercent: Int?
    let date: Date
  }

  class LogEntryCell: UITableViewCell {
    var dateLabel: UILabel
    var scopeLabel: UILabel

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
      dateLabel = UILabel(frame: .zero)
      dateLabel.translatesAutoresizingMaskIntoConstraints = false

      scopeLabel = UILabel(frame: .zero)
      scopeLabel.numberOfLines = 0
      scopeLabel.translatesAutoresizingMaskIntoConstraints = false

      super.init(style: style, reuseIdentifier: reuseIdentifier)

      addSubview(dateLabel)
      addSubview(scopeLabel)
      self.textLabel?.text = ""  // Force creation of labels
      self.detailTextLabel?.text = ""

      if let textLabel = self.textLabel,
         let detailTextLabel = self.detailTextLabel {
        print("hello hello")
        contentView.translatesAutoresizingMaskIntoConstraints = false
        textLabel.translatesAutoresizingMaskIntoConstraints = false
        detailTextLabel.translatesAutoresizingMaskIntoConstraints = false

        let constraints = [
          textLabel.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 20),
          textLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
          textLabel.widthAnchor.constraint(equalTo: contentView.widthAnchor, multiplier: 0.7),

          dateLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
          dateLabel.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: 20),
          dateLabel.widthAnchor.constraint(equalTo: contentView.widthAnchor, multiplier: 0.3),

          detailTextLabel.topAnchor.constraint(equalTo: textLabel.bottomAnchor, constant: 10),
          detailTextLabel.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 20),
          detailTextLabel.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: 20),

          scopeLabel.topAnchor.constraint(equalTo: detailTextLabel.bottomAnchor, constant: 10),
          scopeLabel.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 20),
          scopeLabel.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: 20),
          scopeLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: 20),
        ]
        NSLayoutConstraint.activate(constraints)
      } else {
        print("goodbye forever")
      }
    }
    
    required init?(coder: NSCoder) {
      fatalError("init(coder:) has not been implemented")
    }
  }

  public weak var delegate: ModerationLogViewControllerDelegate?

  private let contents: [LogEntry]
  private let dateFormatter: RelativeDateTimeFormatter

  private var tableView: UITableView!

  public init(contents: [LogEntry]) {
    self.contents = contents
    self.dateFormatter = RelativeDateTimeFormatter()
    self.dateFormatter.unitsStyle = .short
    super.init(nibName: nil, bundle: nil)
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  public override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)

    guard let view = self.view else { return }

    let tableWidth = view.bounds.width
    tableView = UITableView(
      frame: CGRect(x: 0, y: 0, width: tableWidth, height: 0),
      style: .plain
    )
    tableView.allowsMultipleSelectionDuringEditing = true
    tableView.translatesAutoresizingMaskIntoConstraints = false
    tableView.dataSource = self
    tableView.delegate = self
    tableView.register(LogEntryCell.self, forCellReuseIdentifier: "LogEntry")

    view.addSubview(tableView)

    navigationItem.title = "Promoted.ai Stats"
    setDefaultNavigationItems()

    let constraints = [
      view.topAnchor.constraint(equalTo: tableView.topAnchor),
      view.centerXAnchor.constraint(equalTo: tableView.centerXAnchor),
      view.widthAnchor.constraint(equalTo: tableView.widthAnchor),
      view.heightAnchor.constraint(equalTo: tableView.heightAnchor),
    ]
    NSLayoutConstraint.activate(constraints)
  }
}

@available(iOS 13, *)
extension ModerationLogViewController {

  private func setTableViewEditing(_ editing: Bool) {
    tableView.setEditing(editing, animated: true)
    if editing {
      setEditingNavigationItems()
    } else {
      setDefaultNavigationItems()
    }
  }

  private func setDefaultNavigationItems() {
    navigationItem.leftBarButtonItem = UIBarButtonItem(
      title: "Close",
      style: .done,
      target: self,
      action: #selector(close)
    )
    navigationItem.rightBarButtonItem = UIBarButtonItem(
      title: "Edit",
      style: .plain,
      target: self,
      action: #selector(edit)
    )
  }

  private func setEditingNavigationItems() {
    navigationItem.leftBarButtonItem = UIBarButtonItem(
      title: "Select All",
      style: .plain,
      target: self,
      action: #selector(selectAllTableRows)
    )
    navigationItem.rightBarButtonItem = UIBarButtonItem(
      title: "Cancel",
      style: .done,
      target: self,
      action: #selector(cancelEditing)
    )
  }

  @objc private func close() {
    presentingViewController?.dismiss(animated: true)
  }

  @objc private func share() {
    let json = """
    {
      "moderation": ""
    }
    """
    let activityVC = UIActivityViewController(
      activityItems: [json],
      applicationActivities: nil
    )
    activityVC.popoverPresentationController?.sourceView = view
    present(activityVC, animated: true, completion: nil)
  }

  @objc private func edit() {
    setTableViewEditing(true)
  }

  @objc private func cancelEditing() {
    setTableViewEditing(false)
  }

  @objc private func selectAllTableRows() {
    tableView.selectAll(self)
  }
}

@available(iOS 13, *)
extension ModerationLogViewController: UITableViewDataSource {
  public func tableView(
    _ tableView: UITableView,
    numberOfRowsInSection section: Int
  ) -> Int {
    contents.count
  }

  public func tableView(
    _ tableView: UITableView,
    cellForRowAt indexPath: IndexPath
  ) -> UITableViewCell {
    let content = contents[indexPath.item]
    let c = tableView.dequeueReusableCell(withIdentifier: "LogEntry", for: indexPath)
    guard let cell = c as? LogEntryCell else { return c }
    cell.textLabel?.text = content.content.name
    cell.detailTextLabel?.text = { content in
      switch content.action {
      case .shadowban:
        return "Shadowban"
      case .sendToReview:
        return "Sent to Review (moderation@hipcamp.com)"
      case .changeRank:
        if let rankChangePercent = content.rankChangePercent {
          return "Change Rank \(rankChangePercent < 0 ? "–" : "+")\(abs(rankChangePercent))%"
        } else {
          return "Change Rank"
        }
      }
    } (content)
    cell.scopeLabel.text = { content in
      switch content.scope {
      case .global:
        return "Global (All Queries)"
      case .currentSearch:
        return "Scope: \(content.scopeFilter ?? "<unavailable>")"
      }
    } (content)
    cell.dateLabel.text = dateFormatter.localizedString(for: content.date, relativeTo: Date())
    return cell
  }
}

@available(iOS 13, *)
extension ModerationLogViewController: UITableViewDelegate {

  public func tableView(
    _ tableView: UITableView,
    didSelectRowAt indexPath: IndexPath
  ) {
    //
  }
}

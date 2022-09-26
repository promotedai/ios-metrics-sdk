import Foundation
import UIKit

@available(iOS 13, *)
public protocol ModerationLogViewControllerDelegate: AnyObject {

  func moderationLogVC(
    _ vc: ModerationLogViewController,
    didModifyLogEntries entries: [ModerationLogEntry]
  )
}

@available(iOS 13.0, *)
public class ModerationLogViewController: UIViewController {

  class LogEntryCell: UITableViewCell {

    static let height: CGFloat = 80

    var contentLabel: UILabel
    var actionLabel: UILabel
    var dateLabel: UILabel
    var scopeLabel: UILabel

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
      contentLabel = UILabel(frame: .zero)
      contentLabel.font = .boldSystemFont(ofSize: UIFont.systemFontSize + 2)
      contentLabel.translatesAutoresizingMaskIntoConstraints = false

      actionLabel = UILabel(frame: .zero)
      actionLabel.font = .systemFont(ofSize: UIFont.smallSystemFontSize)
      actionLabel.translatesAutoresizingMaskIntoConstraints = false

      dateLabel = UILabel(frame: .zero)
      dateLabel.font = .systemFont(ofSize: UIFont.smallSystemFontSize)
      dateLabel.textAlignment = .right
      dateLabel.textColor = .lightGray
      dateLabel.translatesAutoresizingMaskIntoConstraints = false

      scopeLabel = UILabel(frame: .zero)
      scopeLabel.font = .systemFont(ofSize: UIFont.smallSystemFontSize)
      scopeLabel.textColor = .lightGray
      scopeLabel.numberOfLines = 0
      scopeLabel.translatesAutoresizingMaskIntoConstraints = false

      super.init(style: style, reuseIdentifier: reuseIdentifier)

      contentView.addSubview(contentLabel)
      contentView.addSubview(actionLabel)
      contentView.addSubview(dateLabel)
      contentView.addSubview(scopeLabel)

      let constraints = [
        contentLabel.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 20),
        contentLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
        contentLabel.widthAnchor.constraint(equalTo: contentView.widthAnchor, multiplier: 0.7),

        dateLabel.centerYAnchor.constraint(equalTo: contentLabel.centerYAnchor),
        dateLabel.leftAnchor.constraint(equalTo: contentLabel.rightAnchor, constant: 10),
        dateLabel.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -20),

        actionLabel.topAnchor.constraint(equalTo: contentLabel.bottomAnchor, constant: 4),
        actionLabel.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 20),
        actionLabel.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -20),

        scopeLabel.topAnchor.constraint(equalTo: actionLabel.bottomAnchor, constant: 4),
        scopeLabel.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 20),
        scopeLabel.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -20),
        scopeLabel.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -10),
      ]
      NSLayoutConstraint.activate(constraints)
    }
    
    required init?(coder: NSCoder) {
      fatalError("init(coder:) has not been implemented")
    }
  }

  public weak var delegate: ModerationLogViewControllerDelegate?

  private var contents: [ModerationLogEntry]
  private let dateFormatter: RelativeDateTimeFormatter

  private var tableView: UITableView!

  public init(contents: [ModerationLogEntry]) {
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
    tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Empty")

    tableView.tableFooterView = PromotedLabelFooterView(
      frame: CGRect(x: 0, y: 0, width: tableWidth, height: 100)
    )
    view.addSubview(tableView)

    navigationItem.title = "Promoted.ai Moderation Log"
    toolbarItems = [
      UIBarButtonItem(
        title: "Revert",
        style: .plain,
        target: self,
        action: #selector(revertSelection)
      ),
      UIBarButtonItem(
        barButtonSystemItem: .flexibleSpace,
        target: nil,
        action: nil
      ),
      UIBarButtonItem(
        barButtonSystemItem: .action,
        target: self,
        action: #selector(shareSelection)
      ),
    ]
    updateUI()

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
    updateUI()
  }

  private func updateUI() {
    if contents.count == 0 {
      setDefaultNavigationItems()
      setToolbarItemsEnabled(false)
      navigationItem.rightBarButtonItem?.isEnabled = false
      return
    }
    if tableView.isEditing {
      setEditingNavigationItems()
      navigationController?.setToolbarHidden(false, animated: true)
      if (tableView.indexPathsForSelectedRows ?? []).count > 0 {
        setToolbarItemsEnabled(true)
      } else {
        setToolbarItemsEnabled(false)
      }
    } else {
      setDefaultNavigationItems()
      navigationController?.setToolbarHidden(true, animated: true)
    }
  }

  private func setToolbarItemsEnabled(_ enabled: Bool) {
    guard let items = toolbarItems else { return }
    for item in items {
      item.isEnabled = enabled
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

  @objc private func edit() {
    setTableViewEditing(true)
  }

  @objc private func cancelEditing() {
    setTableViewEditing(false)
  }

  @objc private func selectAllTableRows() {
    for row in 0 ..< contents.count {
      tableView.selectRow(
        at: IndexPath(row: row, section: 0),
        animated: false,
        scrollPosition: .none
      )
    }
  }

  @objc private func revertSelection() {
    guard let selection = tableView.indexPathsForSelectedRows else { return }
    revert(indexPaths: selection)
  }

  private func revert(indexPaths: [IndexPath]) {
    let confirmationAlert = UIAlertController(
      title: "Revert",
      message: "Selected moderation entries will be reverted and no longer affect Promoted.ai Delivery.",
      preferredStyle: .actionSheet
    )
    confirmationAlert.addAction(UIAlertAction(title: "Revert", style: .destructive) {
      [weak self] _ in
      guard let self = self else { return }
      for row in indexPaths.map({ $0.item }).sorted().reversed() {
        self.contents.remove(at: row)
      }
      self.tableView.isEditing = false
      self.tableView.reloadSections(IndexSet(integer: 0), with: .fade)
      self.updateUI()
      self.delegate?.moderationLogVC(self, didModifyLogEntries: self.contents)
    })
    confirmationAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
    present(confirmationAlert, animated: true)
  }

  @objc private func shareSelection() {
    guard let selection = tableView.indexPathsForSelectedRows else { return }
    share(indexPaths: selection)
  }

  private func share(indexPaths: [IndexPath]) {
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
}

@available(iOS 13, *)
extension ModerationLogViewController: UITableViewDataSource {
  public func tableView(
    _ tableView: UITableView,
    numberOfRowsInSection section: Int
  ) -> Int {
    (contents.count == 0) ? 1 : contents.count  // 1 for "No data"
  }

  public func tableView(
    _ tableView: UITableView,
    heightForRowAt indexPath: IndexPath
  ) -> CGFloat {
    LogEntryCell.height
  }

  public func tableView(
    _ tableView: UITableView,
    cellForRowAt indexPath: IndexPath
  ) -> UITableViewCell {
    if contents.count == 0 {
      let c = tableView.dequeueReusableCell(withIdentifier: "Empty", for: indexPath)
      c.textLabel?.text = "No Moderation Actions"
      c.textLabel?.textAlignment = .center
      c.textLabel?.textColor = .gray
      return c
    }

    let content = contents[indexPath.item]
    let c = tableView.dequeueReusableCell(withIdentifier: "LogEntry", for: indexPath)
    guard let cell = c as? LogEntryCell else { return c }
    cell.contentLabel.text = content.content.name
    cell.actionLabel.text = { content in
      switch content.action {
      case .shadowban:
        return "Shadowbaned by ayates@promoted.ai"
      case .sendToReview:
        return "Sent to review by ayates@promoted.ai"
      case .changeRank:
        if let rankChangePercent = content.rankChangePercent {
          return "Rank changed \(rankChangePercent < 0 ? "–" : "+")\(abs(rankChangePercent))% by ayates@promoted.ai"
        } else {
          return "Rank changed by ayates@promoted.ai"
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
    updateUI()
  }

  public func tableView(
    _ tableView: UITableView,
    didDeselectRowAt indexPath: IndexPath
  ) {
    updateUI()
  }

  @available(iOS 13.0, *)
  public func tableView(
    _ tableView: UITableView,
    contextMenuConfigurationForRowAt indexPath: IndexPath,
    point: CGPoint
  ) -> UIContextMenuConfiguration? {
    if indexPath.section != 0 { return nil }
    return UIContextMenuConfiguration(actionProvider: { suggestedActions in
      let shareAction = UIAction(
        title: "Export",
        image: UIImage(systemName: "square.and.arrow.up")
      ) { [weak self] action in
        self?.share(indexPaths: [indexPath])
      }
      let revertAction = UIAction(
        title: "Revert",
        image: UIImage(systemName: "trash"),
        attributes: [.destructive]
      ) { [weak self] action in
        self?.revert(indexPaths: [indexPath])
      }
      return UIMenu(children: [shareAction, revertAction])
    })
  }
}

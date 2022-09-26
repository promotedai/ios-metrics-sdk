import Foundation
import UIKit

public protocol ModerationViewControllerDelegate: AnyObject {

  func moderationVC(
    _ vc: ModerationViewController,
    didApplyAction action: ModerationViewController.ModerationAction,
    scope: ModerationViewController.ModerationScope,
    changeRankPercent: Int
  )
}

public class ModerationViewController: UIViewController {

  struct ListItem {
    let title: String
    let subtitle: String?
    let accessoryType: UITableViewCell.AccessoryType
    let style: UITableViewCell.CellStyle
    let textColor: UIColor?

    init(
      title: String,
      subtitle: String? = nil,
      accessoryType: UITableViewCell.AccessoryType = .none,
      style: UITableViewCell.CellStyle = .subtitle,
      textColor: UIColor? = nil
    ) {
      self.title = title
      self.subtitle = subtitle
      self.accessoryType = accessoryType
      self.style = style
      self.textColor = textColor
    }
  }

  struct ListSection {
    let title: String?
    let contents: [ListItem]
    let footerText: String?

    init(
      title: String?,
      contents: [ListItem],
      footerText: String? = nil
    ) {
      self.title = title
      self.contents = contents
      self.footerText = footerText
    }
  }

  class SliderCell: UITableViewCell {
    let minLabel: UILabel
    let maxLabel: UILabel
    let slider: UISlider

    var isEnabled: Bool {
      get { minLabel.isEnabled && maxLabel.isEnabled && slider.isEnabled }
      set {
        minLabel.isEnabled = newValue
        maxLabel.isEnabled = newValue
        slider.isEnabled = newValue
      }
    }

    init() {
      slider = UISlider(frame: .zero)
      slider.minimumValue = -100
      slider.maximumValue = 100
      slider.translatesAutoresizingMaskIntoConstraints = false

      minLabel = UILabel(frame: .zero)
      minLabel.text = "–100%"
      minLabel.translatesAutoresizingMaskIntoConstraints = false

      maxLabel = UILabel(frame: .zero)
      maxLabel.text = "+100%"
      maxLabel.translatesAutoresizingMaskIntoConstraints = false

      super.init(style: .default, reuseIdentifier: nil)

      addSubview(slider)
      addSubview(minLabel)
      addSubview(maxLabel)

      let constraints = [
        minLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
        slider.centerYAnchor.constraint(equalTo: centerYAnchor),
        maxLabel.centerYAnchor.constraint(equalTo: centerYAnchor),

        minLabel.leftAnchor.constraint(equalTo: leftAnchor, constant: 10),
        slider.leftAnchor.constraint(equalTo: minLabel.rightAnchor, constant: 10),
        slider.rightAnchor.constraint(equalTo: maxLabel.leftAnchor, constant: -10),
        maxLabel.rightAnchor.constraint(equalTo: rightAnchor, constant: -10),
      ]
      NSLayoutConstraint.activate(constraints)
    }

    required init?(coder: NSCoder) {
      fatalError("init(coder:) has not been implemented")
    }
  }

  public enum ModerationScope: Int {
    case global = 0
    case currentSearch = 1

    var description: String {
      switch self {
      case .global:
        return "Applies to all Promoted Delivery requests that involve this item."
      case .currentSearch:
        return "Applies to Promoted Delivery requests matching the current request scope that involve this item."
      }
    }
  }

  public enum ModerationAction: Int {
    case shadowban = 0
    case sendToReview = 1
    case changeRank = 2

    var description: String {
      switch self {
      case .shadowban:
        return "Prevents this item from showing up in listings. Takes effect immediately."
      case .sendToReview:
        return "Flags this item for manual review. Does not immediately change Delivery behavior."
      case .changeRank:
        return "Changes the rank for this item. Takes effect immediately."
      }
    }
  }

  public weak var delegate: ModerationViewControllerDelegate?

  private let params: IntrospectionParams

  private var moderationScope: ModerationScope
  private var moderationAction: ModerationAction
  private var changeRankPercent: Int

  private lazy var contents = [
    ListSection(
      title: "Scope",
      contents: [
        ListItem(
          title: "Global",
          accessoryType: .checkmark
        ),
        ListItem(
          title: "Current Scope",
          subtitle: "Search: campgrounds near Seattle, WA"
        ),
      ],
      footerText: "${moderationScopeDescription}"
    ),
    ListSection(
      title: "Action",
      contents: [
        ListItem(
          title: "Shadowban",
          accessoryType: .checkmark
        ),
        ListItem(
          title: "Send to Review"
        ),
        ListItem(
          title: "Change Rank",
          subtitle: "${changeRankPercent}",
          style: .value1
        ),
      ],
      footerText: "${moderationActionDescription}"
    ),
    ListSection(
      title: "Change Rank",
      contents: [
        ListItem(
          title: "${changeRankPercentSlider}"
        ),
      ]
    ),
    ListSection(
      title: nil,
      contents: [
        ListItem(
          title: "Apply",
          textColor: .systemBlue
        ),
      ]
    ),
  ]

  private var tableView: UITableView!

  public required init(_ params: IntrospectionParams) {
    self.params = params
    self.moderationScope = .global
    self.moderationAction = .shadowban
    self.changeRankPercent = 0
    super.init(nibName: nil, bundle: nil)
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  public override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    guard let view = self.view else { return }

    let tableWidth = view.bounds.width
    let style: UITableView.Style
    if #available(iOS 13.0, *) {
      style = .insetGrouped
    } else {
      style = .grouped
    }
    tableView = UITableView(frame: CGRect(x: 0, y: 0, width: tableWidth, height: 0), style: style)
    tableView.translatesAutoresizingMaskIntoConstraints = false
    tableView.dataSource = self
    tableView.delegate = self

    let headerLabel = UILabel(frame: CGRect(x: 0, y: 0, width: tableWidth, height: 50))
    headerLabel.text = "Content:\n" +
      "Name: \(params.content.name ?? "-")\n" +
      "Content ID: \(params.content.contentID ?? "-")\n" +
      "Insertion ID: \(params.content.insertionID ?? "-")"
    headerLabel.numberOfLines = 0
    tableView.tableHeaderView = headerLabel

    let footerLabel = UILabel(frame: CGRect(x: 0, y: 0, width: tableWidth, height: 50))
    footerLabel.text = "Powered by Promoted.ai Delivery"
    footerLabel.textAlignment = .center
    let footerPanel = UIView(frame: CGRect(x: 0, y: 0, width: tableWidth, height: 100))
    footerPanel.addSubview(footerLabel)
    tableView.tableFooterView = footerPanel
    view.addSubview(tableView)

    navigationItem.title = "Promoted.ai Moderation"
    navigationItem.leftBarButtonItem = UIBarButtonItem(
      title: "Close",
      style: .done,
      target: self,
      action: #selector(close)
    )

    let constraints = [
      view.topAnchor.constraint(equalTo: tableView.topAnchor),
      view.centerXAnchor.constraint(equalTo: tableView.centerXAnchor),
      view.widthAnchor.constraint(equalTo: tableView.widthAnchor),
      view.heightAnchor.constraint(equalTo: tableView.heightAnchor),

      footerLabel.topAnchor.constraint(equalTo: footerPanel.topAnchor),
      footerLabel.centerXAnchor.constraint(equalTo: footerPanel.centerXAnchor),
      footerPanel.heightAnchor.constraint(equalToConstant: 100)
    ]
    NSLayoutConstraint.activate(constraints)
  }

  private func contents(at indexPath: IndexPath) -> ListItem {
    contents[indexPath.section].contents[indexPath.item]
  }
}

extension ModerationViewController {

  @objc private func close() {
    presentingViewController?.dismiss(animated: true)
  }
}

extension ModerationViewController: UITableViewDataSource {

  public func numberOfSections(in tableView: UITableView) -> Int {
    contents.count
  }

  public func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
    contents[section].title
  }

  public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    contents[section].contents.count
  }

  public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let item = contents(at: indexPath)

    if item.title == "${changeRankPercentSlider}" {
      let cell = SliderCell()
      cell.slider.value = Float(changeRankPercent)
      cell.isEnabled = (moderationAction == .changeRank)
      return cell
    }

    let cell = UITableViewCell(style: item.style, reuseIdentifier: nil)

    cell.textLabel?.text = item.title

    cell.detailTextLabel?.text = {
      switch item.subtitle {
      case "${changeRankPercent}":
        return (changeRankPercent >= 0 ? "+" : "–") +
          "\(abs(changeRankPercent))%"
      default:
        return item.subtitle
      }
    } ()

    cell.accessoryType = {
      switch indexPath.section {
      case 0:
        return (indexPath.item == moderationScope.rawValue) ?
          .checkmark : .none
      case 1:
        return (indexPath.item == moderationAction.rawValue) ?
          .checkmark : .none
      default:
        return .none
      }
    } ()

    if let textColor = item.textColor {
      cell.textLabel?.textColor = textColor
    }

    return cell
  }

  public func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
    let text = contents[section].footerText
    switch text {
    case "${moderationScopeDescription}":
      return moderationScope.description
    case "${moderationActionDescription}":
      return moderationAction.description
    default:
      return text
    }
  }
}

extension ModerationViewController: UITableViewDelegate {

  public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    switch indexPath.section {
    case 0:
      guard let newModerationScope = ModerationScope(rawValue: indexPath.item) else { return }
      if moderationScope != newModerationScope {
        moderationScope = newModerationScope
        tableView.reloadSections(IndexSet(integer: 0), with: .automatic)
      }
    case 1:
      guard let newModerationAction = ModerationAction(rawValue: indexPath.item) else { return }
      if moderationAction != newModerationAction {
        moderationAction = newModerationAction
        tableView.reloadSections(IndexSet(integersIn: 1 ... 2), with: .automatic)
      }
    case 2:
      if indexPath.item == 0 {
        delegate?.moderationVC(
          self,
          didApplyAction: moderationAction,
          scope: moderationScope,
          changeRankPercent: changeRankPercent
        )
      }
    default:
      break
    }
  }
}

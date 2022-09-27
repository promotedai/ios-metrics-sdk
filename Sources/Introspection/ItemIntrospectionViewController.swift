import Foundation
import UIKit

public protocol ItemIntrospectionViewControllerDelegate: AnyObject {

  func itemIntrospectionVC(
    _ vc: ItemIntrospectionViewController,
    didSelectItemPropertiesFor params: IntrospectionParams
  )

  func itemIntrospectionVC(
    _ vc: ItemIntrospectionViewController,
    didSelectRequestPropertiesFor params: IntrospectionParams
  )
}

public class ItemIntrospectionViewController: UIViewController {

  enum ListValue {
    case string(_ value: String?)
    case uuid(_ value: String?)
    case searchRank(_ value: Int)
    case decimal(_ value: Double)
    case percent(_ value: Double)
    case itemProperties
    case requestProperties

    static func uuid() -> ListValue { .uuid(UUID().uuidString) }
    static func searchRank() -> ListValue { .searchRank(Int.random(in: 1 ..< 6)) }
    static func percent() -> ListValue { .percent(Double.random(in: 0.0001 ..< 0.03)) }
    static func decimal() -> ListValue { .decimal(Double.random(in: 0.8 ..< 0.95)) }
  }

  struct ListItem {
    let title: String
    let value: ListValue
    let jsonKey: String
  }

  struct ListSection {
    let title: String?
    let contents: [ListItem]
  }

  private static let imageCellIdentifier = "IIImage"

  public weak var delegate: ItemIntrospectionViewControllerDelegate?
  private let params: IntrospectionParams

  private lazy var contents = [
    ListSection(
      title: "Identifiers",
      contents: [
        ListItem(title: "Title", value: .string(params.content.name), jsonKey: "title"),
        ListItem(title: "Content ID", value: .string(params.content.contentID), jsonKey: "contentId"),
        ListItem(title: "User ID", value: .uuid(params.userID), jsonKey: "userId"),
        ListItem(title: "Log User ID", value: .uuid(params.logUserID), jsonKey: "logUserId"),
        ListItem(title: "Insertion ID", value: .uuid(params.content.insertionID), jsonKey: "insertionId"),
        ListItem(title: "Request ID", value: .uuid(), jsonKey: "requestId"),
      ]
    ),
    ListSection(
      title: "Ranking",
      contents: [
        ListItem(title: "Promoted", value: .searchRank(), jsonKey: "promotedRank"),
        ListItem(title: "Retrieval", value: .searchRank(), jsonKey: "retrievalRank"),
      ]
    ),
    ListSection(
      title: "Statistics",
      contents: [
        ListItem(title: "p(Click)", value: .percent(), jsonKey: "pClick"),
        ListItem(title: "p(Purchase)", value: .percent(), jsonKey: "pPurchase"),
        ListItem(title: "30 Day Impr", value: .decimal(), jsonKey: "impressions30Days"),
        ListItem(title: "CTR", value: .decimal(), jsonKey: "ctr"),
        ListItem(title: "Post-Click CVR", value: .decimal(), jsonKey: "cvr"),
        ListItem(title: "Personalization", value: .decimal(), jsonKey: "personalization"),
        ListItem(title: "Price", value: .decimal(), jsonKey: "price"),
      ]
    ),
    ListSection(
      title: "Properties",
      contents: [
        ListItem(title: "Item Properties", value: .itemProperties, jsonKey: ""),
        ListItem(title: "Request Properties", value: .requestProperties, jsonKey: ""),
      ]
    ),
  ]

  private let statsDecimalFormatter: NumberFormatter
  private let statsPercentFormatter: NumberFormatter
  private var tableView: UITableView!
  private var toastView: ToastView!

  public required init(_ params: IntrospectionParams) {
    self.params = params

    statsDecimalFormatter = NumberFormatter()
    statsDecimalFormatter.numberStyle = .decimal
    statsDecimalFormatter.minimumFractionDigits = 3
    statsDecimalFormatter.maximumFractionDigits = 3

    statsPercentFormatter = NumberFormatter()
    statsPercentFormatter.numberStyle = .percent
    statsPercentFormatter.minimumFractionDigits = 2
    statsPercentFormatter.maximumFractionDigits = 2

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

    if let contentHeroImageURL = params.contentHeroImageURL {
      let headerImage = UIImageView(
        frame: CGRect(x: 0, y: 0, width: tableWidth, height: 200),
        asyncImageURLString: contentHeroImageURL
      )
      tableView.tableHeaderView = headerImage
    }
    tableView.tableFooterView = PromotedLabelFooterView(
      frame: CGRect(x: 0, y: 0, width: tableWidth, height: 100)
    )
    view.addSubview(tableView)

    navigationItem.title = "Promoted.ai Stats"
    navigationItem.leftBarButtonItem = UIBarButtonItem(
      title: "Close",
      style: .done,
      target: self,
      action: #selector(close)
    )
    navigationItem.rightBarButtonItem = UIBarButtonItem(
      barButtonSystemItem: .action,
      target: self,
      action: #selector(share)
    )

    toastView = ToastView(
      frame: CGRect(x: 0, y: 0, width: tableWidth, height: 0),
      fontSize: 72
    )
    toastView.isHidden = true
    toastView.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(toastView)

    let constraints = [
      view.topAnchor.constraint(equalTo: tableView.topAnchor),
      view.centerXAnchor.constraint(equalTo: tableView.centerXAnchor),
      view.widthAnchor.constraint(equalTo: tableView.widthAnchor),
      view.heightAnchor.constraint(equalTo: tableView.heightAnchor),

      toastView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
      toastView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
      toastView.widthAnchor.constraint(equalTo: view.widthAnchor),
      toastView.heightAnchor.constraint(equalTo: view.heightAnchor),
    ]
    NSLayoutConstraint.activate(constraints)
  }

  private func contents(at indexPath: IndexPath) -> ListItem {
    contents[indexPath.section].contents[indexPath.item]
  }
}

extension ItemIntrospectionViewController.ListValue {

  func asJSONValue() -> String? {
    asString(quote: "\"")
  }

  func asString(quote: String = "") -> String? {
    switch self {
    case .string(let value): return "\(quote)\(value ?? "")\(quote)"
    case .uuid(let value): return "\(quote)\(value ?? "")\(quote)"
    case .decimal(let value): return "\(value)"
    case .searchRank(let value): return "\(value)"
    case .percent(let value): return "\(value)"
    case .itemProperties, .requestProperties: return nil
    }
  }
}

extension ItemIntrospectionViewController.ListItem {

  func asJSONKeyValuePair() -> String? {
    guard let value = value.asJSONValue() else { return nil }
    return """
    "\(jsonKey)": \(value)
    """
  }
}

extension ItemIntrospectionViewController.ListSection {

  func asJSONMap() -> String? {
    let pairs = contents.compactMap { $0.asJSONKeyValuePair() }
    guard pairs.count > 0 else { return nil }
    return """
    {
      "title": "\(title ?? "")",
      "contents": {
        \(pairs.joined(separator: ",\n    "))
      }
    }
    """
  }
}

extension ItemIntrospectionViewController {

  @objc private func close() {
    presentingViewController?.dismiss(animated: true)
  }

  @objc private func share() {
    let json = """
    {
      \(contents.compactMap { $0.asJSONMap() }.joined(separator: ",\n  "))
    }
    """
    let activityVC = UIActivityViewController(
      activityItems: [json],
      applicationActivities: nil
    )
    activityVC.popoverPresentationController?.sourceView = view
    present(activityVC, animated: true, completion: nil)
  }

  @objc private func copy(indexPath: IndexPath) {
    let item = contents(at: indexPath)
    UIPasteboard.general.string = item.value.asString()
  }

  @objc private func showInLargeType(indexPath: IndexPath) {
    let item = contents(at: indexPath)
    toastView.text = item.value.asString()
    toastView.isHidden = false
  }

  @objc private func hideToast() {
    toastView.isHidden = true
    toastView.text = nil
  }
}

extension ItemIntrospectionViewController: UITableViewDataSource {

  public func numberOfSections(in tableView: UITableView) -> Int {
    contents.count
  }

  public func tableView(
    _ tableView: UITableView,
    titleForHeaderInSection section: Int
  ) -> String? {
    contents[section].title
  }

  public func tableView(
    _ tableView: UITableView,
    numberOfRowsInSection section: Int
  ) -> Int {
    contents[section].contents.count
  }

  public func tableView(
    _ tableView: UITableView,
    cellForRowAt indexPath: IndexPath
  ) -> UITableViewCell {
    let item = contents(at: indexPath)

    let cell = UITableViewCell(style: .value1, reuseIdentifier: nil)
    cell.textLabel?.text = item.title

    cell.detailTextLabel?.text = {
      switch item.value {
      case .string(let value):
        return value ?? "-"
      case .uuid(let value):
        return value ?? "-"
      case .searchRank(let value):
        return "\(value)"
      case .percent(let value):
        return statsPercentFormatter.string(from: NSNumber(value: value))
      case .decimal(let value):
        return statsDecimalFormatter.string(from: NSNumber(value: value))
      case .itemProperties, .requestProperties:
        return nil
      }
    } ()

    cell.detailTextLabel?.font = {
      switch item.value {
      case .uuid(_), .searchRank(_), .percent(_), .decimal(_):
        return UIFont.monospacedDigitSystemFont(
          ofSize: UIFont.systemFontSize,
          weight: .regular
        )
      default:
        return UIFont.systemFont(ofSize: UIFont.systemFontSize)
      }
    } ()

    cell.accessoryType = {
      switch item.value {
      case .itemProperties, .requestProperties:
        return .disclosureIndicator
      default:
        return .none
      }
    } ()

    return cell
  }
}

extension ItemIntrospectionViewController: UITableViewDelegate {

  public func tableView(
    _ tableView: UITableView,
    didSelectRowAt indexPath: IndexPath
  ) {
    let item = contents(at: indexPath)
    switch item.value {
    case .itemProperties:
      print("Item Properties")
      delegate?.itemIntrospectionVC(self, didSelectItemPropertiesFor: params)
    case .requestProperties:
      print("Request Properties")
      delegate?.itemIntrospectionVC(self, didSelectRequestPropertiesFor: params)
    default:
      break
    }
  }

  @available(iOS 13.0, *)
  public func tableView(
    _ tableView: UITableView,
    contextMenuConfigurationForRowAt indexPath: IndexPath,
    point: CGPoint
  ) -> UIContextMenuConfiguration? {
    if indexPath.section != 0 { return nil }
    return UIContextMenuConfiguration(actionProvider: { suggestedActions in
      let copyAction = UIAction(
        title: "Copy",
        image: UIImage(systemName: "doc.on.clipboard")
      ) { [weak self] action in
        self?.copy(indexPath: indexPath)
      }
      let showInLargeTypeAction = UIAction(
        title: "Show in Large Type",
        image: UIImage(systemName: "textformat.size")
      ) { [weak self] action in
        self?.showInLargeType(indexPath: indexPath)
      }
      return UIMenu(children: [copyAction, showInLargeTypeAction])
    })
  }
}

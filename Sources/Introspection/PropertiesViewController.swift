import Foundation
import UIKit

public class PropertiesViewController: UIViewController {

  class HeaderCell: Cell {
    let label = UILabel()
    let sortArrow = UILabel()

    override var frame: CGRect {
      didSet { label.frame = bounds.insetBy(dx: 4, dy: 2) }
    }

    override init(frame: CGRect) {
      super.init(frame: frame)

      label.frame = bounds
      label.autoresizingMask = [.flexibleWidth, .flexibleHeight]
      label.font = UIFont.boldSystemFont(ofSize: 14)
      label.textAlignment = .left
      label.numberOfLines = 2
      contentView.addSubview(label)

      sortArrow.text = ""
      sortArrow.font = UIFont.boldSystemFont(ofSize: 14)
      sortArrow.textAlignment = .center
      contentView.addSubview(sortArrow)
    }

    required init?(coder aDecoder: NSCoder) {
      super.init(coder: aDecoder)
    }

    override func layoutSubviews() {
      super.layoutSubviews()
      sortArrow.sizeToFit()
      sortArrow.frame.origin.x = frame.width - sortArrow.frame.width - 8
      sortArrow.frame.origin.y = (frame.height - sortArrow.frame.height) / 2
    }
  }

  class TextCell: Cell {
    let label = UILabel()

    override var frame: CGRect {
      didSet { label.frame = bounds.insetBy(dx: 4, dy: 2) }
    }

    override init(frame: CGRect) {
      super.init(frame: frame)

      let backgroundView = UIView()
      backgroundView.backgroundColor = UIColor(red: 0, green: 0, blue: 1, alpha: 0.2)
      selectedBackgroundView = backgroundView

      label.frame = bounds
      label.autoresizingMask = [.flexibleWidth, .flexibleHeight]
      label.font = UIFont.monospacedDigitSystemFont(ofSize: 14, weight: .regular)
      label.textAlignment = .left

      contentView.addSubview(label)
    }

    required init?(coder aDecoder: NSCoder) {
      super.init(coder: aDecoder)
    }
  }

  let placeholderContent: [[Any]] = [
    ["ID", "Name", "A", "B", "9/22", "9/21", "9/20", "9/19", "9/18"],
    [101, "Feature Hipcamp Haversine Distance Miles", 5, 0.0036, 53.0, 0.0055, 0.0032, 0.0044, 0.0056],
    [102, "Feature Response Insertion Position", 4, 0.0079, 24.0, 0.0146, 0.0101, 0.0172, 0.0131],
    [103, "Feature Personalize BOOTSTRAP31 Score", 4, 0.0013, 12.0, 0.0048, 0.0001, 0.0002, 0.0076],
    [104, "Feature Hipcamp Search Score", 4, 0.0050, 28.0, 0.0035, 0.0034, 0.0022, 0.0191],
    [105, "Feature Hipcamp Zoom Box Area", 4, 0.0065, 43.0, 0.0059, 0.0082, 0.0069, 0.0107],
    [106, "Feature Personalize Bootstrap N", 4, 0.0039, 66.0, 0.0052, 0.0031, 0.0038, 0.0157],
    [107, "Item Rate Smooth Navigate Impression 30DAY", 3, 0.0099, 38.0, 0.0047, 0.0104, 0.0046, 0.0006],
    [108, "Feature Personalize BOOTSTRAP21 Score", 3, 0.0038, 96.0, 0.0045, 0.0021, 0.0023, 0.0085],
    [109, "Item Elevation", 3, 0.0290, 112.0, 0.0189, 0.0686, 0.0415, 0.0155],
    [110, "Feature Personalize Bootstrap Score", 3, 0.0309, 54.0, 0.0246, 0.0372, 0.0275, 0.0097],
    [111, "Feature Personalize BOOTSTRAP31 Rank", 3, 0.0080, 79.0, 0.0041, 0.0027, 0.0013, 0.0129],
    [112, "Item Rate Smooth Navigate Impression 7DAY", 2, 0.0063, 57.0, 0.0065, 0.0160, 0.0153, 0.0070],
    [113, "Item Rate Raw Navigate Impression 30DAY", 2, 0.0269, 32.0, 0.0161, 0.0407, 0.0226, 0.0292],
    [114, "Feature Device Type", 2, 0.0098, 9.0, 0.0054, 0.0187, 0.0096, 0.0149],
    [115, "Feature Personalize BOOTSTRAP21N", 2, 0.0064, 3.0, 0.0106, 0.0016, 0.0025, 0.0042],
    [116, "Item Rate Raw Navigate Impression 7DAY", 2, 0.0109, 73.0, 0.0072, 0.0434, 0.0267, 0.0314],
    [117, "Item Rate Smooth Checkout Impression 7DAY", 2, 0.0145, 43.0, 0.0111, 0.0283, 0.0201, 0.0187],
    [118, "Feature Personalize Bootstrap Rank", 2, 0.0029, 43.0, 0.0041, 0.0032, 0.0043, 0.0235],
    [119, "Feature User Agent Is iOS", 2, 0.0172, 50.0, 0.0157, 0.0865, 0.0732, 0.0032],
    [120, "Feature Response Paging Size", 2, 0.0296, 34.0, 0.0254, 0.0333, 0.0265, 0.0491],
    [121, "Item Rate Smooth Checkout Impression 30DAY", 2, 0.0370, 78.0, 0.0151, 0.0352, 0.0133, 0.0241],
    [122, "Item Rate Smooth Purchase Navigate 7DAY", 2, 0.0105, 49.0, 0.0448, 0.0056, 0.0221, 0.0139],
    [123, "Feature Personalize BOOTSTRAP31N", 2, 0.0073, 22.0, 0.0270, 0.0040, 0.0137, 0.0622],
    [124, "Item Rate Raw Purchase Impression 30DAY", 2, 0.0029, 10.0, 0.0029, 0.0043, 0.0314, 0.0070],
    [125, "Item Max Vehicles", 2, 0.0172, 13.0, 0.0172, 0.0732, 0.0187, 0.0292],
    [126, "Feature Hipcamp Has Zoom Box", 2, 0.0296, 12.0, 0.0029, 0.0265, 0.0235, 0.0149],
    [127, "Item Count Checkout 30DAY", 2, 0.0370, 5.0, 0.0172, 0.0133, 0.0032, 0.0042],
    [128, "Item Rate Raw Checkout Navigate 7DAY", 2, 0.0296, 65.0, 0.0296, 0.0221, 0.0491, 0.0310]
  ]

  private let params: IntrospectionParams
  private var spreadsheetView: SpreadsheetView!

  public required init(_ params: IntrospectionParams) {
    self.params = params
    super.init(nibName: nil, bundle: nil)
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  public override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)

    view.backgroundColor = UIColor(red: 0.972, green: 0.976, blue: 0.98, alpha: 1.0)

    spreadsheetView = SpreadsheetView(frame: view.bounds)
    spreadsheetView.dataSource = self
    spreadsheetView.register(HeaderCell.self, forCellWithReuseIdentifier: "Header")
    spreadsheetView.register(TextCell.self, forCellWithReuseIdentifier: "Text")
    spreadsheetView.translatesAutoresizingMaskIntoConstraints = false

    view.addSubview(spreadsheetView)

    navigationItem.title = "Properties"
    navigationItem.rightBarButtonItem = UIBarButtonItem(
      barButtonSystemItem: .action,
      target: self,
      action: #selector(share)
    )

    let constraints = [
      spreadsheetView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
      spreadsheetView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
      spreadsheetView.widthAnchor.constraint(equalTo: view.widthAnchor),
      spreadsheetView.heightAnchor.constraint(equalTo: view.heightAnchor),
    ]
    NSLayoutConstraint.activate(constraints)
  }

  private func placeholderContent(at indexPath: IndexPath) -> Any {
    placeholderContent[indexPath.row][indexPath.column]
  }
}

extension PropertiesViewController: SpreadsheetViewDataSource {

  public func numberOfRows(in spreadsheetView: SpreadsheetView) -> Int {
    return placeholderContent.count
  }

  public func numberOfColumns(in spreadsheetView: SpreadsheetView) -> Int {
    return placeholderContent[0].count
  }

  public func spreadsheetView(_ spreadsheetView: SpreadsheetView, widthForColumn column: Int) -> CGFloat {
    return column == 1 ? 200 : 70
  }

  public func spreadsheetView(_ spreadsheetView: SpreadsheetView, heightForRow row: Int) -> CGFloat {
    return 24
  }

  public func spreadsheetView(_ spreadsheetView: SpreadsheetView, cellForItemAt indexPath: IndexPath) -> Cell? {
    let value = placeholderContent(at: indexPath)
    if indexPath.row == 0 {
      if let cell = spreadsheetView.dequeueReusableCell(withReuseIdentifier: "Header", for: indexPath) as? HeaderCell,
         let title = value as? String {
        cell.label.text = title
        return cell
      }
    }
    if let cell = spreadsheetView.dequeueReusableCell(withReuseIdentifier: "Text", for: indexPath) as? TextCell {
      cell.label.text = "\(value)"
      return cell
    }
    return nil
  }

  public func mergedCells(in spreadsheetView: SpreadsheetView) -> [CellRange] {
    return []
  }

  public func frozenColumns(in spreadsheetView: SpreadsheetView) -> Int {
    return 1
  }

  public func frozenRows(in spreadsheetView: SpreadsheetView) -> Int {
    return 1
  }
}

extension PropertiesViewController {

  @objc private func share() {}
}

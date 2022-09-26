import Foundation
import UIKit

class PromotedLabelFooterView: UIView {
  override init(frame: CGRect) {
    super.init(frame: CGRect(x: frame.minX, y: frame.minY, width: frame.width, height: 100))
    let footerLabel = UILabel(frame: CGRect(x: 0, y: 0, width: frame.width, height: 50))
    footerLabel.text = "Powered by Promoted.ai Delivery"
    footerLabel.textAlignment = .center
    addSubview(footerLabel)

    let constraints = [
      footerLabel.topAnchor.constraint(equalTo: topAnchor),
      footerLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
      heightAnchor.constraint(equalToConstant: 100),
    ]
    NSLayoutConstraint.activate(constraints)
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}

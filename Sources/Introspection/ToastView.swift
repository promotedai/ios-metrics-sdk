import Foundation
import UIKit

class ToastView: UIView {

  private let label: UILabel

  var text: String? {
    get { label.attributedText?.string }
    set {
      guard let newValue = newValue else {
        label.attributedText = nil
        return
      }
      label.attributedText = NSAttributedString(
        string: newValue,
        attributes: [
          .font: UIFont.systemFont(ofSize: 72),
          .foregroundColor: UIColor.white,
        ]
      )
    }
  }

  var autoHide: Bool

  override var isHidden: Bool {
    get { super.isHidden }
    set {
      super.isHidden = newValue
      if !newValue && autoHide {
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(2)) {
          [weak self] in
          guard let self = self else { return }
          if !self.isHidden {
            self.isHidden = true
          }
        }
      }
    }
  }

  override init(frame: CGRect) {
    let background = UIView(frame: frame)
    background.backgroundColor = UIColor(white: 0, alpha: 0.5)
    background.isUserInteractionEnabled = true
    background.layer.cornerRadius = 20
    background.translatesAutoresizingMaskIntoConstraints = false
    label = UILabel(frame: frame)
    label.isUserInteractionEnabled = true
    label.lineBreakMode = .byCharWrapping
    label.numberOfLines = 0
    label.translatesAutoresizingMaskIntoConstraints = false
    self.autoHide = false
    super.init(frame: frame)
    translatesAutoresizingMaskIntoConstraints = false
    addSubview(background)
    addSubview(label)
    isUserInteractionEnabled = true
    let recognizer = UITapGestureRecognizer(target: self, action: #selector(hide))
    addGestureRecognizer(recognizer)
    background.addGestureRecognizer(recognizer)
    label.addGestureRecognizer(recognizer)
    let constraints = [
      background.centerXAnchor.constraint(equalTo: centerXAnchor),
      background.centerYAnchor.constraint(equalTo: centerYAnchor),
      background.widthAnchor.constraint(lessThanOrEqualTo: widthAnchor, constant: -10),
      background.heightAnchor.constraint(lessThanOrEqualTo: heightAnchor, constant: -10),
      label.centerXAnchor.constraint(equalTo: centerXAnchor),
      label.centerYAnchor.constraint(equalTo: centerYAnchor),
      label.widthAnchor.constraint(lessThanOrEqualTo: background.widthAnchor, constant: -10),
      label.heightAnchor.constraint(lessThanOrEqualTo: background.heightAnchor, constant: -10),
    ]
    NSLayoutConstraint.activate(constraints)
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  @objc private func hide(sender: UIGestureRecognizer) {
    isHidden = true
  }
}

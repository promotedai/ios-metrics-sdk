import Foundation
import UIKit

class ToastView: UIView {

  private let label: UILabel
  private let imageView: UIImageView
  private var textOnlyConstraints: [NSLayoutConstraint]!
  private var textAndImageConstraints: [NSLayoutConstraint]!

  var text: String? {
    get { label.attributedText?.string }
    set {
      guard let newValue = newValue else {
        label.attributedText = nil
        return
      }
      let text = NSAttributedString(
        string: newValue,
        attributes: [
          .font: UIFont.systemFont(ofSize: localFontSize),
          .foregroundColor: UIColor.white,
        ]
      )
      label.attributedText = text
    }
  }

  private var localFontSize: CGFloat
  var fontSize: CGFloat {
    get { localFontSize }
    set {
      localFontSize = newValue
      text = text
      label.lineBreakMode = (
        fontSize > 20 ?
          .byCharWrapping :
          .byWordWrapping
      )
    }
  }

  var image: UIImage? {
    get { imageView.image }
    set {
      imageView.image = newValue
      if newValue == nil {
        imageView.isHidden = true
        NSLayoutConstraint.deactivate(textAndImageConstraints)
        NSLayoutConstraint.activate(textOnlyConstraints)
      } else {
        imageView.isHidden = false
        NSLayoutConstraint.deactivate(textOnlyConstraints)
        NSLayoutConstraint.activate(textAndImageConstraints)
      }
    }
  }

  var autoHide: Bool {
    didSet {
      if autoHide {
        startAutoHideTimer()
      }
    }
  }

  var shouldRemoveFromSuperviewOnAutoHide: Bool

  override var isHidden: Bool {
    get { super.isHidden }
    set {
      super.isHidden = newValue
      if !newValue && autoHide {
        startAutoHideTimer()
      }
    }
  }

  init(frame: CGRect, fontSize: CGFloat) {
    localFontSize = fontSize

    let background = UIView(frame: frame)
    background.backgroundColor = UIColor(white: 0, alpha: 0.8)
    background.isUserInteractionEnabled = true
    background.layer.cornerRadius = 20
    background.translatesAutoresizingMaskIntoConstraints = false

    label = UILabel(frame: frame)
    label.isUserInteractionEnabled = true
    label.numberOfLines = 0
    label.translatesAutoresizingMaskIntoConstraints = false

    imageView = UIImageView(frame: frame)
    imageView.isHidden = true
    imageView.isUserInteractionEnabled = true
    imageView.translatesAutoresizingMaskIntoConstraints = false

    self.autoHide = false
    self.shouldRemoveFromSuperviewOnAutoHide = false

    super.init(frame: frame)

    translatesAutoresizingMaskIntoConstraints = false

    textOnlyConstraints = [
      background.centerXAnchor.constraint(equalTo: centerXAnchor),
      background.centerYAnchor.constraint(equalTo: centerYAnchor),
      background.widthAnchor.constraint(lessThanOrEqualTo: widthAnchor, constant: -20),
      background.heightAnchor.constraint(lessThanOrEqualTo: heightAnchor, constant: -20),

      label.centerXAnchor.constraint(equalTo: centerXAnchor),
      label.centerYAnchor.constraint(equalTo: centerYAnchor),
      label.widthAnchor.constraint(lessThanOrEqualTo: background.widthAnchor, constant: -20),
      label.heightAnchor.constraint(lessThanOrEqualTo: background.heightAnchor, constant: -20),
    ]
    textAndImageConstraints = [
      background.centerXAnchor.constraint(equalTo: centerXAnchor),
      background.centerYAnchor.constraint(equalTo: centerYAnchor),
      background.widthAnchor.constraint(equalTo: imageView.widthAnchor),
      background.bottomAnchor.constraint(equalTo: label.bottomAnchor, constant: 20),

      imageView.centerXAnchor.constraint(equalTo: background.centerXAnchor),
      imageView.topAnchor.constraint(equalTo: background.topAnchor, constant: 20),
      imageView.widthAnchor.constraint(equalToConstant: 200),
      imageView.heightAnchor.constraint(equalToConstant: 100),

      label.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 10),
      label.centerXAnchor.constraint(equalTo: centerXAnchor),
      label.widthAnchor.constraint(lessThanOrEqualTo: background.widthAnchor, constant: -20),
      label.heightAnchor.constraint(lessThanOrEqualTo: background.heightAnchor, constant: -20),
    ]

    addSubview(background)
    addSubview(imageView)
    addSubview(label)

    backgroundColor = UIColor(white: 0, alpha: 0.2)
    isUserInteractionEnabled = true

    let recognizer = UITapGestureRecognizer(
      target: self,
      action: #selector(hide)
    )
    addGestureRecognizer(recognizer)
    background.addGestureRecognizer(recognizer)
    label.addGestureRecognizer(recognizer)

    NSLayoutConstraint.activate(textOnlyConstraints)
    NSLayoutConstraint.deactivate(textAndImageConstraints)
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  public override func didMoveToSuperview() {
    super.didMoveToSuperview()
    guard let superview = superview else { return }
    let constraints = [
      widthAnchor.constraint(equalTo: superview.widthAnchor),
      heightAnchor.constraint(equalTo: superview.heightAnchor),
    ]
    NSLayoutConstraint.activate(constraints)
  }

  @objc private func hide(sender: UIGestureRecognizer) {
    isHidden = true
  }

  private func startAutoHideTimer() {
    DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(2)) {
      [weak self] in
      guard let self = self else { return }
      UIView.animate(
        withDuration: 0.2,
        animations: { self.layer.opacity = 0 },
        completion: { finished in
          if self.shouldRemoveFromSuperviewOnAutoHide {
            self.removeFromSuperview()
          } else if !self.isHidden {
            self.isHidden = true
            self.layer.opacity = 1
          }
        }
      )
    }
  }
}

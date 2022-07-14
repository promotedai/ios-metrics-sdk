import Foundation
import UIKit

/** Delegate for interactions with the AnomalyModalVC. */
protocol AnomalyModalViewControllerDelegate: AnyObject {
  func anomalyModalVCDidDismiss(
    _ vc: AnomalyModalViewController,
    shouldShowAgain: Bool
  )
}

/** Presents a modal with detailed error message. */
class AnomalyModalViewController: UIViewController {

  weak var delegate: AnomalyModalViewControllerDelegate?

  private let partner: String
  private let contactInfo: [String]
  private let anomalyType: AnomalyType

  private var shouldShowAgain: Bool

  init(
    partner: String,
    contactInfo: [String],
    anomalyType: AnomalyType,
    delegate: AnomalyModalViewControllerDelegate?
  ) {
    self.partner = partner
    self.contactInfo = contactInfo
    self.anomalyType = anomalyType
    self.delegate = delegate
    self.shouldShowAgain = true
    super.init(nibName: nil, bundle: nil)
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)

    guard let view = self.view else { return }
    let backdropWidth = view.bounds.width - 40
    let textWidth = backdropWidth - 40
    let textLayoutFrame = CGRect(x: 0, y: 0, width: textWidth, height: 0)

    let backdrop = UIView()
    backdrop.backgroundColor = UIColor(white: 0, alpha: 0.9)
    backdrop.layer.cornerRadius = 20
    backdrop.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(backdrop)

    let titleLabel = UILabel(frame: textLayoutFrame)
    titleLabel.font = .boldSystemFont(ofSize: 16)
    titleLabel.text = "Promoted.ai Logging Issue"
    titleLabel.textColor = .white
    titleLabel.translatesAutoresizingMaskIntoConstraints = false
    backdrop.addSubview(titleLabel)

    let explanationLabel = UILabel(frame: textLayoutFrame)
    explanationLabel.numberOfLines = 0  // Use as many lines as needed.
    explanationLabel.text = """
    Description: \(anomalyType.debugDescription)

    Error code: \(anomalyType.rawValue)
    """
    explanationLabel.textColor = .white
    explanationLabel.translatesAutoresizingMaskIntoConstraints = false
    backdrop.addSubview(explanationLabel)

    let helpLabel = UILabel(frame: textLayoutFrame)
    helpLabel.font = .systemFont(ofSize: 14)
    helpLabel.numberOfLines = 0  // Use as many lines as needed.
    helpLabel.text = """
    If this issue is released to production, it WILL impair Promoted Delivery and possibly affect revenue at \(partner). Please verify any local changes carefully before merging.

    For more help, contact Promoted:

    \(contactInfo.map { "• " + $0 }.joined(separator: "\n"))

    This warning will only appear in development builds.
    """
    helpLabel.textColor = .white
    helpLabel.translatesAutoresizingMaskIntoConstraints = false
    backdrop.addSubview(helpLabel)

    let dontShowAgainButton = UIButton()
    dontShowAgainButton.addTarget(
      self,
      action: #selector(dismissDontShowAgain),
      for: .touchUpInside
    )
    dontShowAgainButton.setTitle("Don’t Show Again", for: .normal)
    dontShowAgainButton.setTitleColor(.white, for: .normal)
    dontShowAgainButton.titleLabel?.font = .boldSystemFont(ofSize: 16)
    dontShowAgainButton.translatesAutoresizingMaskIntoConstraints = false
    backdrop.addSubview(dontShowAgainButton)

    let continueButton = UIButton()
    continueButton.addTarget(self, action: #selector(dismissContinue), for: .touchUpInside)
    continueButton.setTitle("Continue", for: .normal)
    continueButton.setTitleColor(.white, for: .normal)
    continueButton.titleLabel?.font = .boldSystemFont(ofSize: 16)
    continueButton.translatesAutoresizingMaskIntoConstraints = false
    backdrop.addSubview(continueButton)

    let container: UILayoutGuide
    if #available(iOS 11.0, *) {
      container = view.safeAreaLayoutGuide
    } else {
      container = view.layoutMarginsGuide
    }
    let constraints = [
      backdrop.leftAnchor.constraint(equalTo: container.leftAnchor, constant: 20),
      backdrop.rightAnchor.constraint(equalTo: container.rightAnchor, constant: -20),
      backdrop.centerYAnchor.constraint(equalTo: container.centerYAnchor),
      backdrop.bottomAnchor.constraint(equalTo: continueButton.bottomAnchor, constant: 20),

      titleLabel.topAnchor.constraint(equalTo: backdrop.topAnchor, constant: 20),
      titleLabel.centerXAnchor.constraint(equalTo: backdrop.centerXAnchor),

      explanationLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 20),
      explanationLabel.leftAnchor.constraint(equalTo: backdrop.leftAnchor, constant: 20),
      explanationLabel.rightAnchor.constraint(equalTo: backdrop.rightAnchor, constant: -20),

      helpLabel.topAnchor.constraint(equalTo: explanationLabel.bottomAnchor, constant: 20),
      helpLabel.leftAnchor.constraint(equalTo: backdrop.leftAnchor, constant: 20),
      helpLabel.rightAnchor.constraint(equalTo: backdrop.rightAnchor, constant: -20),

      dontShowAgainButton.topAnchor.constraint(equalTo: helpLabel.bottomAnchor, constant: 20),
      dontShowAgainButton.leftAnchor.constraint(equalTo: backdrop.leftAnchor, constant: 20),
      dontShowAgainButton.rightAnchor.constraint(equalTo: backdrop.rightAnchor, constant: -20),

      continueButton.topAnchor.constraint(equalTo: dontShowAgainButton.bottomAnchor, constant: 10),
      continueButton.leftAnchor.constraint(equalTo: backdrop.leftAnchor, constant: 20),
      continueButton.rightAnchor.constraint(equalTo: backdrop.rightAnchor, constant: -20),
    ]
    NSLayoutConstraint.activate(constraints)
  }

  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    if isBeingDismissed {
      delegate?.anomalyModalVCDidDismiss(self, shouldShowAgain: shouldShowAgain)
    }
  }

  @objc private func dismissContinue() {
    self.presentingViewController?.dismiss(animated: true)
  }

  @objc private func dismissDontShowAgain() {
    shouldShowAgain = false
    self.presentingViewController?.dismiss(animated: true)
  }
}

#if DEBUG || PROMOTED_ERROR_HANDLING

import Foundation
import UIKit

/** Delegate for interactions with the AnomalyModalVC. */
public protocol ErrorModalViewControllerDelegate: AnyObject {
  func errorModalVCDidDismiss(
    _ vc: ErrorModalViewController,
    shouldShowAgain: Bool
  )
}

/**
 Presents a modal with detailed error message. Clients should not use this
 class directly.

 Although this class is intended only for internal use in the Promoted metrics
 library, it is declared public so that ReactNativeMetrics can show the modal
 for module initialization issues.
 */
public class ErrorModalViewController: UIViewController {

  weak var delegate: ErrorModalViewControllerDelegate?

  private let partner: String
  private let contactInfo: [String]
  private let errorDetails: String
  private let errorCode: Int?

  private var shouldShowAgain: Bool

  public required init(
    partner: String,
    contactInfo: [String],
    error: Error,
    delegate: ErrorModalViewControllerDelegate?
  ) {
    self.partner = partner
    self.contactInfo = contactInfo
    if let d = error as? ErrorDetails {
      self.errorDetails = d.details
    } else {
      self.errorDetails = error.externalDescription
    }
    self.errorCode = error.asErrorProperties()?.code
    self.delegate = delegate
    self.shouldShowAgain = true
    super.init(nibName: nil, bundle: nil)
    if #available(iOS 13.0, *) {
      self.isModalInPresentation = true  // Prevent dragging down to dismiss
    }
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  public override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)

    guard let view = self.view else { return }
    let backdropWidth = view.bounds.width - 40
    let textWidth = backdropWidth - 40
    let textLayoutFrame = CGRect(x: 0, y: 0, width: textWidth, height: 0)

    let blurEffect = UIBlurEffect(style: .dark)
    let backdrop = UIVisualEffectView(effect: blurEffect)
    backdrop.clipsToBounds = true
    backdrop.layer.cornerRadius = 20
    backdrop.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(backdrop)

    let titleLabel = UILabel(frame: textLayoutFrame)
    titleLabel.font = .boldSystemFont(ofSize: 16)
    titleLabel.text = "Promoted.ai Logging Issue"
    titleLabel.textColor = .white
    titleLabel.translatesAutoresizingMaskIntoConstraints = false
    backdrop.contentView.addSubview(titleLabel)

    let explanationLabel = UILabel(frame: textLayoutFrame)
    explanationLabel.numberOfLines = 0  // Use as many lines as needed.
    var explanationLabelText = errorDetails
      .replacingOccurrences(of: "$partner", with: partner)
    if let code = errorCode {
      explanationLabelText += "\n\nError code: \(code)"
    }
    explanationLabel.text = explanationLabelText
    explanationLabel.textColor = .white
    explanationLabel.translatesAutoresizingMaskIntoConstraints = false
    backdrop.contentView.addSubview(explanationLabel)

    let helpLabel = UILabel(frame: textLayoutFrame)
    helpLabel.font = .systemFont(ofSize: 14)
    helpLabel.numberOfLines = 0  // Use as many lines as needed.
    helpLabel.text = """
    For more help, contact Promoted:

    \(contactInfo.map { "• " + $0 }.joined(separator: "\n"))

    This warning will only appear in development builds.
    """
    helpLabel.textColor = .white
    helpLabel.translatesAutoresizingMaskIntoConstraints = false
    backdrop.contentView.addSubview(helpLabel)

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
    backdrop.contentView.addSubview(dontShowAgainButton)

    let continueButton = UIButton()
    continueButton.addTarget(self, action: #selector(dismissContinue), for: .touchUpInside)
    continueButton.setTitle("Continue", for: .normal)
    continueButton.setTitleColor(.white, for: .normal)
    continueButton.titleLabel?.font = .boldSystemFont(ofSize: 16)
    continueButton.translatesAutoresizingMaskIntoConstraints = false
    backdrop.contentView.addSubview(continueButton)

    let constraints = [
      backdrop.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 20),
      backdrop.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -20),
      backdrop.centerYAnchor.constraint(equalTo: view.centerYAnchor),
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

  public override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    if isBeingDismissed {
      delegate?.errorModalVCDidDismiss(self, shouldShowAgain: shouldShowAgain)
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

#endif

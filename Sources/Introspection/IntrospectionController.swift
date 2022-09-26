import Foundation
import UIKit

public class IntrospectionController {

  private var logEntries: [ModerationLogEntry]

  public init() {
    logEntries = [
      ModerationLogEntry(
        content: Content(name: "Botany Bay", contentID: "16309"),
        action: .shadowban,
        scope: .global,
        scopeFilter: nil,
        rankChangePercent: nil,
        date: Calendar.current.date(byAdding: .day, value: -1, to: Date())!
      ),
      ModerationLogEntry(
        content: Content(name: "Sacramento Utopia", contentID: "74656"),
        action: .sendToReview,
        scope: .global,
        scopeFilter: nil,
        rankChangePercent: nil,
        date: Calendar.current.date(byAdding: .day, value: -2, to: Date())!
      ),
      ModerationLogEntry(
        content: Content(name: "Wild Wild West Coast", contentID: "74208"),
        action: .sendToReview,
        scope: .global,
        scopeFilter: nil,
        rankChangePercent: nil,
        date: Calendar.current.date(byAdding: .day, value: -2, to: Date())!
      ),
    ]
  }

  public func showIntrospectionActionSelectorSheet(_ params: IntrospectionParams) {
    let alert = UIAlertController(title: "Promoted.ai Introspection", message: nil, preferredStyle: .actionSheet)
    alert.addAction(UIAlertAction(title: "Introspection", style: .default) {
      [weak self] _ in
      self?.showItemIntrospection(params)
    })
    alert.addAction(UIAlertAction(title: "Moderation", style: .default) {
      [weak self] _ in
      self?.showModeration(params)
    })
    if #available(iOS 13, *) {
      alert.addAction(UIAlertAction(title: "Moderation Log", style: .default) {
        [weak self] _ in
        self?.showModerationLog()
      })
    }
    alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) {
      [weak alert] _ in
      alert?.presentingViewController?.dismiss(animated: true)
    })
    alert.presentAboveKeyWindowRootVC()
  }

  public func showItemIntrospection(_ params: IntrospectionParams) {
    let itemVC = ItemIntrospectionViewController(params)
    itemVC.delegate = self
    let nc = UINavigationController(rootViewController: itemVC)
    nc.modalPresentationStyle = .overFullScreen
    nc.presentAboveKeyWindowRootVC()
  }

  public func showModeration(_ params: IntrospectionParams) {
    let moderationVC = ModerationViewController(params)
    moderationVC.delegate = self
    let nc = UINavigationController(rootViewController: moderationVC)
    nc.presentAboveKeyWindowRootVC()
  }

  @available(iOS 13, *)
  public func showModerationLog() {
    let logVC = ModerationLogViewController(contents: logEntries)
    logVC.delegate = self
    let nc = UINavigationController(rootViewController: logVC)
    nc.presentAboveKeyWindowRootVC()
  }
}

extension IntrospectionController: ItemIntrospectionViewControllerDelegate {

  public func itemIntrospectionVC(
    _ vc: ItemIntrospectionViewController,
    didSelectItemPropertiesFor params: IntrospectionParams
  ) {
    guard let nc = vc.navigationController else { return }
    let propertiesVC = PropertiesViewController(params, propertiesType: .item)
    nc.pushViewController(propertiesVC, animated: true)
  }

  public func itemIntrospectionVC(
    _ vc: ItemIntrospectionViewController,
    didSelectRequestPropertiesFor params: IntrospectionParams
  ) {
    guard let nc = vc.navigationController else { return }
    let propertiesVC = PropertiesViewController(params, propertiesType: .request)
    nc.pushViewController(propertiesVC, animated: true)
  }
}

extension IntrospectionController: ModerationViewControllerDelegate {

  public func moderationVC(
    _ vc: ModerationViewController,
    didApplyActionWithLogEntry entry: ModerationLogEntry
  ) {
    guard let nc = vc.navigationController else { return }
    nc.presentingViewController?.dismiss(animated: true)
    logEntries.append(entry)
  }
}

@available(iOS 13, *)
extension IntrospectionController: ModerationLogViewControllerDelegate {

  public func moderationLogVC(
    _ vc: ModerationLogViewController,
    didModifyLogEntries entries: [ModerationLogEntry]
  ) {
    logEntries = entries
  }
}

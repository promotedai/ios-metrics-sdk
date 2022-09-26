import Foundation
import UIKit

public class IntrospectionController {

  public init() {}

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
    didApplyAction action: ModerationViewController.ModerationAction,
    scope: ModerationViewController.ModerationScope,
    changeRankPercent: Int
  ) {
    guard let nc = vc.navigationController else { return }
    nc.presentingViewController?.dismiss(animated: true)
  }
}

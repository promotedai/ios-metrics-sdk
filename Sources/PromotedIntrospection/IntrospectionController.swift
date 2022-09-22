import Foundation
import UIKit

public class IntrospectionController {



  public func showIntrospectionActionSelectorSheet(_ params: IntrospectionParams) {
    let alert = UIAlertController(title: "Promoted.ai Introspection", message: nil, preferredStyle: .actionSheet)
    alert.addAction(UIAlertAction(title: "Show Introspection", style: .default) {
      [weak self] _ in
      self?.showItemIntrospection(params)
    })
    alert.addAction(UIAlertAction(title: "Show Moderation", style: .default) {
      [weak self] _ in
      self?.showModeration()
    })
    alert.presentAboveKeyWindowRootVC()
  }

  public func showItemIntrospection(_ params: IntrospectionParams) {
    let itemVC = ItemIntrospectionViewController(params)
    let nc = UINavigationController(rootViewController: itemVC)
    nc.presentAboveKeyWindowRootVC()
  }

  public func showModeration() {

  }
}

extension IntrospectionController: ItemIntrospectionViewControllerDelegate {
  public func itemIntrospectionVC(_ vc: ItemIntrospectionViewController, didSelectItemPropertiesFor params: IntrospectionParams) {
    guard let nc = vc.navigationController else { return }
  }
  public func itemIntrospectionVC(_ vc: ItemIntrospectionViewController, didSelectRequestPropertiesFor params: IntrospectionParams) {
    guard let nc = vc.navigationController else { return }
  }
}

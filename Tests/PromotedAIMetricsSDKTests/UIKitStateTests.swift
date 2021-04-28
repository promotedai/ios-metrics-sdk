import Foundation
import UIKit
import XCTest

@testable import PromotedAIMetricsSDK

final class UIKitStateTests: XCTestCase {
  
  private class FakePresentingViewController: UIViewController {
    private var fakePresented: UIViewController? = nil
    override var presentedViewController: UIViewController? {
      return fakePresented
    }
    override func present(_ viewControllerToPresent: UIViewController,
                          animated flag: Bool,
                          completion: (() -> Void)? = nil) {
      fakePresented = viewControllerToPresent
    }
  }

  func testSingleVC() {
    let vc = UIViewController()
    let actual = UIKitState.viewControllerStack(root: vc)
    XCTAssertEqual([vc], actual)
  }
  
  func testNavigationController() {
    let nc = UINavigationController()
    let vc1 = UIViewController()
    let vc2 = UIViewController()
    nc.pushViewController(vc1, animated: false)
    nc.pushViewController(vc2, animated: false)
    let actual = UIKitState.viewControllerStack(root: nc)
    XCTAssertEqual([nc, vc1, vc2], actual)
  }
  
  func testTabBarController() {
    let tc = UITabBarController()
    let vc1 = UIViewController()
    let vc2 = UIViewController()
    let vc3 = UIViewController()
    tc.viewControllers = [vc1, vc2, vc3]
    tc.selectedViewController = vc3
    let actual = UIKitState.viewControllerStack(root: tc)
    XCTAssertEqual([tc, vc3], actual)
  }
  
  func testPresentedViewController() {
    let presentingVC = FakePresentingViewController()
    let vc = UIViewController()
    presentingVC.present(vc, animated: false, completion: nil)
    let actual = UIKitState.viewControllerStack(root: presentingVC)
    XCTAssertEqual([presentingVC, vc], actual)
  }
  
  func testChildViewController() {
    let parentVC = UIViewController()
    let childVC = UIViewController()
    parentVC.addChild(childVC)
    let actual = UIKitState.viewControllerStack(root: parentVC)
    XCTAssertEqual([parentVC, childVC], actual)
  }
  
  func testChildViewControllerHierarchy() {
    let rootVC = UIViewController()
    let c1 = UIViewController()
    let c2 = UIViewController()
    let c11 = UIViewController()
    let c12 = UIViewController()
    let c21 = UIViewController()
    rootVC.addChild(c1)
    rootVC.addChild(c2)
    c1.addChild(c11)
    c1.addChild(c12)
    c2.addChild(c21)
    let actual = UIKitState.viewControllerStack(root: rootVC)
    XCTAssertEqual([rootVC, c1, c2, c11, c12, c21], actual)
  }
  
  /// Queenly
  func testMultiplePresentedViewControllers() {
    let rootVC = FakePresentingViewController()
    let nc1 = UINavigationController()
    let vc1 = FakePresentingViewController()
    let nc2 = UINavigationController()
    let vc2 = UIViewController()
    rootVC.present(nc1, animated: false, completion: nil)
    nc1.pushViewController(vc1, animated: false)
    vc1.present(nc2, animated: false, completion: nil)
    nc2.pushViewController(vc2, animated: false)
    let actual = UIKitState.viewControllerStack(root: rootVC)
    XCTAssertEqual([rootVC, nc1, vc1, nc2, vc2], actual)
  }
  
  /// Queenly
  func testPresentFromChildViewController() {
    let rootVC = UIViewController()
    let c1 = UIViewController()
    let c2 = FakePresentingViewController()
    let p1 = UIViewController()
    rootVC.addChild(c1)
    rootVC.addChild(c2)
    c2.present(p1, animated: false, completion: nil)
    let actual = UIKitState.viewControllerStack(root: rootVC)
    XCTAssertEqual([rootVC, c1, c2, p1], actual)
  }
}

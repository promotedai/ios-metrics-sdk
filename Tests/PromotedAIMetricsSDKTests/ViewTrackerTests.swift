import Foundation
import UIKit
import XCTest

@testable import PromotedAIMetricsSDK
@testable import TestHelpers

final class ViewTrackerTests: XCTestCase {
  private let idMap = FakeIDMap()
  private let uiState = FakeUIState()
  private lazy var viewTracker = ViewTracker(idMap: idMap, uiState: uiState)

  override func setUp() {
    super.setUp()
    idMap.incrementCounts = true
  }

  func testTrackViewUIKit() {
    let viewIDBefore = viewTracker.viewID
    let vc = UIViewController()
    let state = viewTracker.trackView(key: .uiKit(viewController: vc), useCase: .feed)
    let viewIDAfter = viewTracker.viewID
    XCTAssertEqual(viewIDBefore, viewIDAfter)
    XCTAssertEqual(ViewTracker.Key.uiKit(viewController: vc), state!.viewKey)
    XCTAssertEqual(UseCase.feed, state!.useCase)
    XCTAssertEqual(viewIDBefore, state!.viewID)
  }
  
  func testTrackSameViewUIKit() {
    let viewIDBefore = viewTracker.viewID

    let vc1 = UIViewController()
    let state1 = viewTracker.trackView(key: .uiKit(viewController: vc1), useCase: .feed)
    XCTAssertNotNil(state1)

    // Tracking same VC should provide nil state.
    let state2 = viewTracker.trackView(key: .uiKit(viewController: vc1), useCase: .feed)
    XCTAssertNil(state2)
    let viewIDAfter = viewTracker.viewID
    XCTAssertEqual(viewIDBefore, viewIDAfter)
  }
  
  func testTrackViewUIKitMultiple() {
    let viewIDBefore = viewTracker.viewID

    let vc1 = UIViewController()
    let state1 = viewTracker.trackView(key: .uiKit(viewController: vc1), useCase: .feed)
    let viewID1 = viewTracker.viewID
    XCTAssertEqual(viewIDBefore, viewID1)
    XCTAssertEqual(ViewTracker.Key.uiKit(viewController: vc1), state1!.viewKey)
    XCTAssertEqual(UseCase.feed, state1!.useCase)
    XCTAssertEqual(viewIDBefore, state1!.viewID)
    
    let vc2 = UIViewController()
    let state2 = viewTracker.trackView(key: .uiKit(viewController: vc2), useCase: .search)
    let viewID2 = viewTracker.viewID
    XCTAssertNotEqual(viewIDBefore, viewID2)
    XCTAssertNotEqual(viewID1, viewID2)
    XCTAssertEqual(ViewTracker.Key.uiKit(viewController: vc2), state2!.viewKey)
    XCTAssertEqual(UseCase.search, state2!.useCase)
    XCTAssertEqual(viewID2, state2!.viewID)
    
    let vc3 = UIViewController()
    let state3 = viewTracker.trackView(key: .uiKit(viewController: vc3), useCase: .custom)
    let viewID3 = viewTracker.viewID
    XCTAssertNotEqual(viewIDBefore, viewID3)
    XCTAssertNotEqual(viewID1, viewID3)
    XCTAssertNotEqual(viewID2, viewID3)
    XCTAssertEqual(ViewTracker.Key.uiKit(viewController: vc3), state3!.viewKey)
    XCTAssertEqual(UseCase.custom, state3!.useCase)
    XCTAssertEqual(viewID3, state3!.viewID)
  }
  
  func testTrackViewUIKitMultiplePopToPreviousTracked() {
    let vc1 = UIViewController()
    let state1 = viewTracker.trackView(key: .uiKit(viewController: vc1), useCase: .feed)
    XCTAssertNotNil(state1)
    
    let vc2 = UIViewController()
    let state2 = viewTracker.trackView(key: .uiKit(viewController: vc2), useCase: .search)
    XCTAssertNotNil(state2)
    
    let vc3 = UIViewController()
    let state3 = viewTracker.trackView(key: .uiKit(viewController: vc3), useCase: .custom)
    XCTAssertNotNil(state3)
    
    let finalState = viewTracker.trackView(key: .uiKit(viewController: vc1), useCase: .feed)
    XCTAssertEqual(state1, finalState)
  }
  
  func testTrackViewUIKitMultipleNilUpdate() {
    let vc1 = UIViewController()
    let state1 = viewTracker.trackView(key: .uiKit(viewController: vc1), useCase: .feed)
    XCTAssertNotNil(state1)
    
    let vc2 = UIViewController()
    let state2 = viewTracker.trackView(key: .uiKit(viewController: vc2), useCase: .search)
    XCTAssertNotNil(state2)
    
    let vc3 = UIViewController()
    let state3 = viewTracker.trackView(key: .uiKit(viewController: vc3), useCase: .custom)
    XCTAssertNotNil(state3)

    // No change in VC stack should provide nil state.
    uiState.viewControllers = [vc1, vc2, vc3]
    let updatedState = viewTracker.updateState()
    XCTAssertNil(updatedState)
  }
  
  func testTrackViewUIKitMultipleUpdate() {
    let vc1 = UIViewController()
    let state1 = viewTracker.trackView(key: .uiKit(viewController: vc1), useCase: .feed)
    XCTAssertNotNil(state1)
    
    let vc2 = UIViewController()
    let state2 = viewTracker.trackView(key: .uiKit(viewController: vc2), useCase: .search)
    XCTAssertNotNil(state2)
    
    let vc3 = UIViewController()
    let state3 = viewTracker.trackView(key: .uiKit(viewController: vc3), useCase: .custom)
    XCTAssertNotNil(state3)

    // Simulate vc2 and vc3 being popped off stack.
    uiState.viewControllers = [vc1]
    let finalState = viewTracker.updateState()
    XCTAssertEqual(state1, finalState)
  }
  
  func testTrackViewUIKitRegenerate() {
    let vc1 = UIViewController()
    let state1 = viewTracker.trackView(key: .uiKit(viewController: vc1), useCase: .feed)
    XCTAssertNotNil(state1)
    
    let vc2 = UIViewController()  // Don't log vc2.
    
    let vc3 = UIViewController()
    let state3 = viewTracker.trackView(key: .uiKit(viewController: vc3), useCase: .custom)
    XCTAssertNotNil(state3)

    // vc2 shouldn't appear in the stack.
    uiState.viewControllers = [vc1, vc2, vc3]
    _ = viewTracker.updateState()
    let stack = viewTracker.viewStackForTesting
    XCTAssertEqual([state1, state3], stack)
  }
  
  func testTrackViewReactNative() {
    let viewIDBefore = viewTracker.viewID
    let key = ViewTracker.Key.reactNative(routeName: "foo", routeKey: "bar")
    let state = viewTracker.trackView(key: key, useCase: .categoryContent)
    let viewIDAfter = viewTracker.viewID
    XCTAssertEqual(viewIDBefore, viewIDAfter)
    XCTAssertEqual(key, state!.viewKey)
    XCTAssertEqual(UseCase.categoryContent, state!.useCase)
    XCTAssertEqual(viewIDBefore, state!.viewID)
  }
  
  func testTrackViewReactNativeMultiplePopToPreviousTracked() {
    let key1 = ViewTracker.Key.reactNative(routeName: "foo", routeKey: "bar")
    let state1 = viewTracker.trackView(key: key1)
    XCTAssertNotNil(state1)
    
    let key2 = ViewTracker.Key.reactNative(routeName: "batman", routeKey: "robin")
    let state2 = viewTracker.trackView(key: key2)
    XCTAssertNotNil(state2)
    
    let key3 = ViewTracker.Key.reactNative(routeName: "simon", routeKey: "garfunkle")
    let state3 = viewTracker.trackView(key: key3)
    XCTAssertNotNil(state3)
    
    let finalState = viewTracker.trackView(key: key1)
    XCTAssertEqual(state1, finalState)
  }
  
  func testTrackViewReactNativeReset() {
    let key1 = ViewTracker.Key.reactNative(routeName: "foo", routeKey: "bar")
    let state1 = viewTracker.trackView(key: key1)
    XCTAssertNotNil(state1)

    let key2 = ViewTracker.Key.reactNative(routeName: "batman", routeKey: "robin")
    let state2 = viewTracker.trackView(key: key2)
    XCTAssertNotNil(state2)

    viewTracker.reset()
    XCTAssertNotEqual(viewTracker.viewID, state2!.viewID)

    let state3 = viewTracker.trackView(key: key1)
    XCTAssertNotNil(state3)
    XCTAssertNotEqual(state1!.viewID, state3!.viewID)
  }
}

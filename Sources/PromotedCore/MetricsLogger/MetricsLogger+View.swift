import Foundation
import SwiftProtobuf
import UIKit

// MARK: - View Logging Methods (ObjC)

public extension MetricsLogger {

  /// Logs a view of the given `UIViewController`.
  @objc func logView(viewController: UIViewController) {
    logView(trackerKey: .uiKit(viewController: viewController))
  }
  
  /// Logs a view of the given `UIViewController` and use case.
  @objc func logView(
    viewController: UIViewController,
    useCase: UseCase
  ) {
    logView(
      trackerKey: .uiKit(viewController: viewController),
      useCase: useCase
    )
  }
}

// MARK: - View Logging Methods (Swift)

public extension MetricsLogger {

  /// Logs a view with the given route name and key (React Native).
  @discardableResult
  func logView(
    routeName: String?,
    routeKey: String?
  ) -> Event_View {
    return logView(name: routeName)
  }

  @discardableResult
  internal func logView(
    name: String? = nil,
    useCase: UseCase? = nil,
    viewID: String? = nil,
    properties: Message? = nil
  ) -> Event_View {
    var view = Event_View()
    withMonitoredExecution(needsViewStateCheck: false) {
      view.timing = timingMessage()
      if let v = viewID ?? self.viewID { view.viewID = v }
      if let s = sessionID { view.sessionID = s }
      if let n = name { view.name = n }
      if let u = useCase?.protoValue { view.useCase = u }
      if let p = propertiesMessage(properties) { view.properties = p }
      view.locale = localeMessage()
      view.viewType = .appScreen
      let appScreenView = Event_AppScreenView()
      // TODO(yuhong): Fill out AppScreenView.
      view.appScreenView = appScreenView
      if let i = identifierProvenancesMessage(
        platformSpecifiedViewID: viewID,
        internalViewID: viewTracker.id.currentValue
      ) {
        view.idProvenances = i
      }
      log(message: view)
      history?.viewIDDidChange(value: view.viewID, event: view)
    }
    return view
  }
}

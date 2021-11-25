import Foundation
import SwiftProtobuf
import UIKit

public extension MetricsLogger {

  /// Logs a view with the given route name and key (React Native).
  @discardableResult
  func logAutoView(
    routeName: String?,
    routeKey: String?,
    autoViewID: String?
  ) -> Event_AutoView {
    return logAutoView(name: routeName, autoViewID: autoViewID)
  }

  @discardableResult
  func logAutoView(
    name: String? = nil,
    useCase: UseCase? = nil,
    autoViewID: String? = nil,
    properties: Message? = nil
  ) -> Event_AutoView {
    var autoView = Event_AutoView()
    withMonitoredExecution {
      autoView.timing = timingMessage()
      if let a = autoViewID { autoView.autoViewID = a }
      if let s = sessionID { autoView.sessionID = s }
      if let n = name { autoView.name = n }
      if let u = useCase?.protoValue { autoView.useCase = u }
      if let p = propertiesMessage(properties) { autoView.properties = p }
      autoView.locale = cachedLocaleMessage
      let appScreenView = Event_AppScreenView()
      // TODO(yuhong): Fill out AppScreenView.
      autoView.appScreenView = appScreenView
      if let i = identifierProvenancesMessage(
        config: config,
        autoViewID: autoViewID
      ) {
        autoView.idProvenances = i
      }
      log(message: autoView)
      history?.autoViewIDDidChange(value: viewID, event: autoView)
    }
    return autoView
  }
}

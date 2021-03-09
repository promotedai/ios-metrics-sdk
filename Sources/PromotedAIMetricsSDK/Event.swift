import Foundation
import SwiftProtobuf

// MARK: -
/** Base class of all `Event` objects to provide a non-generic type. */
open class AnyEvent {
  open func messageForLogging() -> Message? {
    assertionFailure("Subclasses must override messageForLogging.")
    return nil
  }
}

// MARK: -
/** Represents a logged event with both a common and client messages. */
open class Event<CommonMessage>: AnyEvent where CommonMessage: Message {
  public var clientMessage: Message?
  public var commonMessage: CommonMessage?
  
  public init(clientMessage: Message? = nil,
              commonMessage: CommonMessage? = nil) {
    self.clientMessage = clientMessage
    self.commonMessage = commonMessage
  }
}

// MARK: -

open class User: Event<Event_User> {
  public func fillCommon(timestamp: Clock.TimeIntervalMillis,
                         userID: String? = nil,
                         logUserID: String? = nil) {
    var user = Event_User()
    if let id = userID { user.userID = id }
    if let id = logUserID { user.logUserID = id }
    user.clientLogTimestamp = timestamp
    commonMessage = user
  }
}

// MARK: -

open class Impression: Event<Event_Impression> {
  public func fillCommon(timestamp: Clock.TimeIntervalMillis,
                         impressionID: String,
                         insertionID: String? = nil,
                         requestID: String? = nil,
                         sessionID: String? = nil,
                         viewID: String? = nil) {
    var impression = Event_Impression()
    impression.clientLogTimestamp = timestamp
    impression.impressionID = impressionID
    if let id = insertionID { impression.insertionID = id }
    if let id = requestID { impression.requestID = id }
    if let id = sessionID { impression.sessionID = id }
    if let id = viewID { impression.viewID = id }
    commonMessage = impression
  }
}

// MARK: -

open class Click: Event<Event_Click> {
  public func fillCommon(timestamp: Clock.TimeIntervalMillis,
                         clickID: String,
                         impressionID: String? = nil,
                         insertionID: String? = nil,
                         requestID: String? = nil,
                         sessionID: String? = nil,
                         viewID: String? = nil,
                         name: String? = nil,
                         targetURL: String? = nil,
                         elementID: String? = nil) {
    var click = Event_Click()
    click.clientLogTimestamp = timestamp
    click.clickID = clickID
    if let id = impressionID { click.impressionID = id }
    if let id = insertionID { click.insertionID = id }
    if let id = requestID { click.requestID = id }
    if let id = sessionID { click.sessionID = id }
    if let id = viewID { click.viewID = id }
    if let s = name { click.name = s }
    if let u = targetURL { click.targetURL = u }
    if let id = elementID { click.elementID = id }
    commonMessage = click
  }
}

// MARK: -

open class View: Event<Event_View> {
  public func fillCommon(timestamp: Clock.TimeIntervalMillis,
                         viewID: String,
                         sessionID: String? = nil,
                         name: String? = nil,
                         url: String? = nil,
                         useCase: Event_UseCase? = nil) {
    var view = Event_View()
    view.clientLogTimestamp = timestamp
    view.viewID = viewID
    if let id = sessionID { view.sessionID = id }
    if let n = name { view.name = n }
    if let u = url { view.url = u }
    if let use = useCase { view.useCase = use }
    commonMessage = view
  }
}

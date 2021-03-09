import Foundation
import SwiftProtobuf

// MARK: -
/** Base class of all `Event` objects to provide a non-generic type. */
open class AnyEvent {
  open func messageForLogging() -> Message? {
    return nil
  }
}

// MARK: -
/** Represents a logged event with both a common and client messages. */
open class Event<ClientMessage, CommonMessage>: AnyEvent
    where ClientMessage: Message, CommonMessage: Message {
  public var clientMessage: ClientMessage?
  public var commonMessage: CommonMessage?
  
  public init(clientMessage: ClientMessage? = nil,
              commonMessage: CommonMessage? = nil) {
    self.clientMessage = clientMessage
    self.commonMessage = commonMessage
  }
  
  open override func messageForLogging() -> Message? {
    return clientMessage
  }
}

// MARK: -
/**
 Used in place of `User<?>` in common code, where we don't ever access
 `clientMessage` directly.
 */
typealias AnyUser = User<Event_User>

open class User<U>: Event<U, Event_User> where U: Message {
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
/**
 Used in place of `Impression<?>` in common code, where we don't ever access
 `clientMessage` directly.
 */
typealias AnyImpression = Impression<Event_Impression>

open class Impression<I>: Event<I, Event_Impression> where I: Message {
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
/**
 Used in place of `Click<?>` in common code, where we don't ever access
 `clientMessage` directly.
 */
typealias AnyClick = Click<Event_Click>

open class Click<C>: Event<C, Event_Click> where C: Message {
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
/**
 Used in place of `View<?>` in common code, where we don't ever access
 `clientMessage` directly.
 */
typealias AnyView = View<Event_View>

open class View<V>: Event<V, Event_View> where V: Message {
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

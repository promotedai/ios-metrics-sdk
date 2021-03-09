import Foundation
import SwiftProtobuf

@testable import PromotedAIMetricsSDK

public typealias FakeUser = AnyUser
public typealias FakeImpression = AnyImpression
public typealias FakeClick = AnyClick
public typealias FakeView = AnyView

public class FakeMessageProvider: MessageProvider {
  public func userMessage<Event_User>() -> User<Event_User> {
    return FakeUser() as! User<Event_User>
  }

  public func impressionMessage<Event_Impression>() ->
      Impression<Event_Impression> {
    return FakeImpression() as! Impression<Event_Impression>
  }
  
  public func clickMessage<Event_Click>() -> Click<Event_Click> {
    return FakeClick() as! Click<Event_Click>
  }
  
  public func viewMessage<Event_View>() -> View<Event_View> {
    return FakeView() as! View<Event_View>
  }
  
  public func batchLogMessage(events: [Message],
                              userID: String?,
                              logUserID: String?) -> Message {
    return Event_User()
  }
}

import Foundation
import PromotedAIMetricsSDK

public class BaseMessageProvider: MessageProvider {
  public func userMessage<Event_User>(
      commonMessage: Event_User,
      clientMessage: Event_User?) -> Message {
    return commonMessage
  }
  
  public func impressionMessage<Event_Impression>(
      commonMessage: Event_Impression,
      clientMessage: Event_Impression?) -> Message {
    return commonMessage
  }
  
  public func clickMessage<Event_Click>(
      commonMessage: Event_Click,
      clientMessage: Event_Click?) -> Message {
    return commonMessage
  }
  
  public func viewMessage<Event_View>(
      commonMessage: Event_View,
      clientMessage: Event_View?) -> Message {
    return commonMessage
  }
  
  public func batchLogMessage(events: [Message],
                              userID: String?,
                              logUserID: String?) -> Message {
    return Event_User()
  }
}

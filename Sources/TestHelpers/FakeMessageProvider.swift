import Foundation
import SwiftProtobuf

@testable import PromotedAIMetricsSDK

public class FakeUser: User {
  public override func messageForLogging() -> Message? {
    return commonMessage
  }
}

public class FakeImpression: Impression {
  public override func messageForLogging() -> Message? {
    return commonMessage
  }
}

public class FakeClick: Click {
  public override func messageForLogging() -> Message? {
    return commonMessage
  }
}

public class FakeView: View {
  public override func messageForLogging() -> Message? {
    return commonMessage
  }
}

public class FakeMessageProvider: MessageProvider {
  public func userMessage() -> User {
    return FakeUser()
  }

  public func impressionMessage() -> Impression {
    return FakeImpression()
  }
  
  public func clickMessage() -> Click {
    return FakeClick()
  }
  
  public func viewMessage() -> View {
    return FakeView()
  }
  
  public func batchLogMessage(events: [Message],
                              userID: String?,
                              logUserID: String?) -> Message {
    return Event_User()
  }
}

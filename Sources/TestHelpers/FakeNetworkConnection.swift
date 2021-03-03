import Foundation
import PromotedAIMetricsSDK
import SwiftProtobuf

public class FakeNetworkConnection: NetworkConnection {
  
  public struct SendMessageArguments {
    public let message: Message?
    public let url: URL?
    public let callback: Callback?
  }
  
  public var messages: [SendMessageArguments]
  
  public init() {
    messages = []
  }
  
  public func sendMessage(_ message: Message, url: URL, clientConfig: ClientConfig,
                          callback: Callback?) throws {
    messages.append(SendMessageArguments(message: message, url: url, callback: callback))
  }
}

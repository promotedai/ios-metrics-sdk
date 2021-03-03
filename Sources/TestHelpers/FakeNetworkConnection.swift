import Foundation
import PromotedAIMetricsSDK
import SwiftProtobuf

public class FakeNetworkConnection: NetworkConnection {
  
  public struct SendMessageArguments {
    let message: Message?
    let url: URL?
    let callback: Callback?
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

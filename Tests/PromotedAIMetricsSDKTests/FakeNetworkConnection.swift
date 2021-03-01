import Foundation
import SwiftProtobuf
@testable import PromotedAIMetricsSDK

class FakeNetworkConnection: NetworkConnection {
  
  struct SendMessageArguments {
    let message: Message?
    let url: URL?
    let callback: Callback?
  }
  
  var messages: [SendMessageArguments]
  
  init() {
    messages = []
  }
  
  func sendMessage(_ message: Message, url: URL, callback: Callback?) throws {
    messages.append(SendMessageArguments(message: message, url: url, callback: callback))
  }
}

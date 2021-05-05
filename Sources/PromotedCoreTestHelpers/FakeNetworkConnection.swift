import Foundation
import SwiftProtobuf

@testable import PromotedCore

class FakeNetworkConnection: NetworkConnection {
  
  struct SendMessageArguments {
    let message: Message?
    let callback: Callback?
  }
  
  var messages: [SendMessageArguments]

  init() {
    messages = []
  }
  
  func sendMessage(_ message: Message,
                   clientConfig: ClientConfig,
                   xray: Xray?,
                   callback: Callback?) throws {
    messages.append(SendMessageArguments(message: message, callback: callback))
  }
}

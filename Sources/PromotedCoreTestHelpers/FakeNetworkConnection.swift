import Foundation
import SwiftProtobuf

@testable import PromotedCore

final class FakeNetworkConnection: NetworkConnection {
  
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
                   callback: Callback?) throws -> Data {
    messages.append(SendMessageArguments(message: message, callback: callback))
    return try message.serializedData()
  }
}

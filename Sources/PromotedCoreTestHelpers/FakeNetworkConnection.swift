import Foundation
import SwiftProtobuf

@testable import PromotedCore

final class FakeNetworkConnection: NetworkConnection {
  
  struct SendMessageArguments {
    let message: Message?
    let callback: Callback?
  }
  
  var messages: [SendMessageArguments]
  var throwOnNextSendMessage: Error?

  init() {
    messages = []
  }
  
  func sendMessage(_ message: Message,
                   clientConfig: ClientConfig,
                   callback: Callback?) throws -> Data {
    if let error = throwOnNextSendMessage {
      // If we need to throw an error, then don't include
      // the message/callback in the capture list.
      throwOnNextSendMessage = nil
      throw error
    }
    messages.append(SendMessageArguments(message: message, callback: callback))
    return try message.serializedData()
  }
}

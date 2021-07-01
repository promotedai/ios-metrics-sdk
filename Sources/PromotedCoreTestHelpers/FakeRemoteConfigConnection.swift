import Foundation

@testable import PromotedCore

final class FakeRemoteConfigConnection: RemoteConfigConnection {

  var config: ClientConfig? = ClientConfig()
  var error: RemoteConfigConnectionError? = nil
  var messages: PendingLogMessages = PendingLogMessages()

  func fetchClientConfig(
    initialConfig: ClientConfig,
    callback: @escaping Callback
  ) throws {
    let result = Result(config: config, error: error, messages: messages)
    callback(result)
  }
}

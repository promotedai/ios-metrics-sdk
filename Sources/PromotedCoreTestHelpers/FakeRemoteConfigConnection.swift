import Foundation

@testable import PromotedCore

final class FakeRemoteConfigConnection: RemoteConfigConnection {

  var config: ClientConfig = ClientConfig()

  func fetchClientConfig(
    initialConfig: ClientConfig,
    callback: @escaping Callback
  ) throws {
    callback(config, nil)
  }
}

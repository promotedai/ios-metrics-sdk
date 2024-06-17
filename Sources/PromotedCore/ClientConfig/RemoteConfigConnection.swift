import Foundation

/**
 Loads `ClientConfig` across the network. The loaded config
 is cached to disk and used in subsequent startups of the
 logging system.
 */
public protocol RemoteConfigConnection: AnyObject {

  func fetchClientConfig(
    initialConfig: ClientConfig
  ) async throws -> ClientConfig
}

protocol RemoteConfigConnectionSource {
  var remoteConfigConnection: RemoteConfigConnection? { get }
}

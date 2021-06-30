import Foundation

/**
 Loads `ClientConfig` across the network. The loaded config
 is cached to disk and used in subsequent startups of the
 logging system.
 */
public protocol RemoteConfigConnection: AnyObject {

  typealias Callback = (ClientConfig?, Error?) -> Void

  func fetchClientConfig(initialConfig: ClientConfig,
                         callback: @escaping Callback) throws
}

protocol RemoteConfigConnectionSource: NoDeps {
  var remoteConfigConnection: RemoteConfigConnection? { get }
}

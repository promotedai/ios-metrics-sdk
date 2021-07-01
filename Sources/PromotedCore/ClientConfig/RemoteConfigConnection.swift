import Foundation

public struct _RemoteConfigConnectionResult {
  public let config: ClientConfig?
  public let error: Error?
  public let messages: PendingLogMessages

  public init(
    config: ClientConfig?,
    error: Error?,
    messages: PendingLogMessages
  ) {
    self.config = config
    self.error = error
    self.messages = messages
  }
}

/**
 Loads `ClientConfig` across the network. The loaded config
 is cached to disk and used in subsequent startups of the
 logging system.
 */
public protocol RemoteConfigConnection: AnyObject {

  typealias Result = _RemoteConfigConnectionResult
  typealias Callback = (Result) -> Void

  func fetchClientConfig(
    initialConfig: ClientConfig,
    callback: @escaping Callback
  )
}

protocol RemoteConfigConnectionSource {
  var remoteConfigConnection: RemoteConfigConnection? { get }
}

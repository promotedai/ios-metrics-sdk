import Foundation

#if canImport(GTMSessionFetcherCore)
import GTMSessionFetcherCore
#elseif canImport(GTMSessionFetcher)
import GTMSessionFetcher
#else
#error("Can't import GTMSessionFetcher")
#endif

#if canImport(SwiftProtobuf)
import SwiftProtobuf
#endif

@objc(PROMetricsLogger)
open class MetricsLogger: NSObject {

  private let config: ClientConfig
  private let fetcherService: GTMSessionFetcherService
  private let clock: Clock
  private let store: PersistentStore
  private var events: [Message]
  
  private let metricsLoggingURL: URL?

  private(set) var userID: String?
  private(set) var logUserID: String?

  @objc public init(clientConfig: ClientConfig,
                    fetcherService: GTMSessionFetcherService,
                    clock: Clock,
                    store: PersistentStore) {
    self.config = clientConfig
    self.fetcherService = fetcherService
    self.clock = clock
    self.store = store
    self.events = []
    self.userID = nil
    self.logUserID = nil
    self.metricsLoggingURL = URL(string: config.metricsLoggingURL)
  }
  
  @objc public func startSession(userID: String) {
    startSessionAndUpdateUserIDs(userID: userID)
  }
  
  @objc public func startSessionSignedOut() {
    startSessionAndUpdateUserIDs(userID: nil)
  }
  
  private func startSessionAndUpdateUserIDs(userID: String?) {
    self.userID = userID
    if let cachedLogUserID = store.logUserID {
      if userID == store.userID {
        self.logUserID = cachedLogUserID
        return
      }
    }
    store.userID = userID
    let uuid = UUID()
    let newLogUserID = uuid.uuidString
    store.logUserID = newLogUserID
    self.logUserID = newLogUserID
  }

  public func commonUserEvent() -> Event_User {
    var user = Event_User()
    if let id = userID { user.userID = id }
    if let id = logUserID { user.logUserID = id }
    user.clientLogTimestamp = clock.nowMillis
    return user
  }

  public func commonImpressionEvent(
      impressionID: String,
      insertionID: String? = nil,
      requestID: String? = nil,
      sessionID: String? = nil,
      viewID: String? = nil) -> Event_Impression {
    var impression = Event_Impression()
    if let id = logUserID { impression.logUserID = id }
    impression.clientLogTimestamp = clock.nowMillis
    impression.impressionID = impressionID
    if let id = insertionID { impression.insertionID = id }
    if let id = requestID { impression.requestID = id }
    if let id = sessionID { impression.sessionID = id }
    if let id = viewID { impression.viewID = id }
    return impression
  }
  
  public func commonClickEvent(
      clickID: String,
      impressionID: String? = nil,
      insertionID: String? = nil,
      requestID: String? = nil,
      sessionID: String? = nil,
      viewID: String? = nil,
      name: String? = nil,
      targetURL: String? = nil,
      elementID: String? = nil) -> Event_Click {
    var click = Event_Click()
    if let id = logUserID { click.logUserID = id }
    click.clientLogTimestamp = clock.nowMillis
    click.clickID = clickID
    if let id = impressionID { click.impressionID = id }
    if let id = insertionID { click.insertionID = id }
    if let id = requestID { click.requestID = id }
    if let id = sessionID { click.sessionID = id }
    if let id = viewID { click.viewID = id }
    if let s = name { click.name = s }
    if let u = targetURL { click.targetURL = u }
    if let id = elementID { click.elementID = id }
    return click
  }
  
  public func log(event: Message) {
    events.append(event)
  }

  /** Subclasses should override to provide batch protos. */
  open func batchLogMessage(events: [Message]) -> Message? {
    // TODO(yu-hong): Update if we have a common batch message.
    return nil
  }

  @objc public func flush() {
    let eventsCopy = events
    events.removeAll()
    guard let batchMessage = batchLogMessage(events: eventsCopy) else { return }
    guard let url = metricsLoggingURL else { return }
    do {
      let messageData = try batchMessage.serializedData()
      let request = URLRequest(url: url)
      let fetcher = fetcherService.fetcher(with: request)
      fetcher.allowLocalhostRequest = true
      fetcher.bodyData = messageData
      fetcher.beginFetch { (data, error) in
        guard error == nil else {
          print("ERROR: \(error.debugDescription)")
          return
        }
        print("Fetch finished: \(String(describing: data))")
      }
    } catch BinaryEncodingError.missingRequiredFields {
      print("ERROR: SwiftProtobuf: Missing required fields.")
    } catch BinaryEncodingError.anyTranscodeFailure {
      print("ERROR: SwiftProtobuf: Any transcode failed.")
    } catch {
      print("ERROR: Error serializing protobuf.")
    }
  }
}

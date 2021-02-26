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
  private var events: [Message]
  
  private let metricsLoggingURL: URL?

  private var userID: String
  private var logUserID: String
  private var sessionID: String

  @objc public init(clientConfig: ClientConfig,
                    fetcherService: GTMSessionFetcherService,
                    clock: Clock) {
    self.config = clientConfig
    self.fetcherService = fetcherService
    self.clock = clock
    self.events = []
    self.userID = "userID"
    self.logUserID = "logUserID"
    self.sessionID = "sessionID"
    
    self.metricsLoggingURL = URL(string: config.metricsLoggingURL)
  }
  
  public func commonUserEvent() -> UserEvent {
    var user = UserEvent()
    Protobuf.SilenceVarWarning(&user)
    user.userID = userID
    user.logUserID = logUserID
    user.clientLogTimestamp = clock.nowMillis
    return user
  }

  public func commonImpressionEvent(
      impressionID: String,
      insertionID: String? = nil,
      requestID: String? = nil,
      viewID: String? = nil) -> ImpressionEvent {
    var impression = ImpressionEvent()
    Protobuf.SilenceVarWarning(&impression)
    impression.logUserID = logUserID
    impression.clientLogTimestamp = clock.nowMillis
    impression.impressionID = impressionID
    if let id = insertionID { impression.insertionID = id }
    if let id = requestID { impression.requestID = id}
    impression.sessionID = sessionID
    if let id = viewID { impression.viewID = id }
    return impression
  }
  
  public func commonClickEvent(
      clickID: String,
      impressionID: String? = nil,
      insertionID: String? = nil,
      requestID: String? = nil,
      viewID: String? = nil,
      name: String? = nil,
      targetURL: String? = nil,
      elementID: String? = nil) -> ClickEvent {
    var click = ClickEvent()
    Protobuf.SilenceVarWarning(&click)
    click.logUserID = logUserID
    click.clientLogTimestamp = clock.nowMillis
    click.clickID = clickID
    if let id = impressionID { click.impressionID = id }
    if let id = insertionID { click.insertionID = id }
    click.sessionID = sessionID
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
    } catch MessageSerializationError.unknownError {
      print("ERROR: ObjCProtobuf: Error serializing protobuf.")
    } catch {
      print("ERROR: Error serializing protobuf.")
    }
  }
}

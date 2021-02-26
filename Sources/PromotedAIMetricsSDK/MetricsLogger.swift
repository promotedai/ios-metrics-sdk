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
  
  private static let localMetricsLoggingURLString = "http://localhost:8080/metrics"
  
  private let fetcherService: GTMSessionFetcherService
  private let metricsLoggingURL: URL
  private let clock: Clock
  private var events: [LogMessage]

  private var userID: String
  private var logUserID: String
  private var sessionID: String
  
  @objc public override convenience init() {
    self.init(fetcherService: GTMSessionFetcherService())
  }
  
  @objc public convenience init(fetcherService: GTMSessionFetcherService) {
    let dummyURL = URL(string: MetricsLogger.localMetricsLoggingURLString)!
    self.init(fetcherService: fetcherService, metricsLoggingURL: dummyURL, clock: SystemClock())
  }
  
  public init(fetcherService: GTMSessionFetcherService, metricsLoggingURL: URL, clock: Clock) {
    self.fetcherService = fetcherService
    self.metricsLoggingURL = metricsLoggingURL
    self.clock = clock
    self.events = []
    self.userID = "userID"
    self.logUserID = "logUserID"
    self.sessionID = "sessionID"
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
  
  public func log(event: LogMessage) {
    events.append(event)
  }

  /** Subclasses should override to provide batch protos. */
  open func batchLogMessage(events: [LogMessage]) -> LogMessage? {
    return nil
  }

  @objc public func flush() {
    guard let batchMessage = batchLogMessage(events: events) else { return }
    events.removeAll()
    do {
      let messageData = try batchMessage.serializedData()
      let request = URLRequest(url: metricsLoggingURL)
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

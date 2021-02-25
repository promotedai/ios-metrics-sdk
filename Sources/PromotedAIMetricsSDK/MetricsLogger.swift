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

@objc(PAMetricsLogger)
open class MetricsLogger: NSObject {
  
  public typealias ClientData = Dictionary<String, AnyObject>
  
  private var fetcherService: GTMSessionFetcherService
  private var events: [LogMessage]
  
  private var logUserID: String
  private var sessionID: String
  
  @objc public override convenience init() {
    self.init(fetcherService: GTMSessionFetcherService())
  }
  
  @objc public init(fetcherService: GTMSessionFetcherService) {
    self.fetcherService = fetcherService
    self.events = []
    self.logUserID = "logUserID"
    self.sessionID = "sessionID"
  }
  
  public func commonSessionStartEvent() -> SessionEvent {
    var session = SessionEvent()
    session.clientLogTimestamp = MetricsTimestamp()
    session.logUserID = logUserID
    session.platformID = 0
    session.sessionID = sessionID
    return session
  }

  public func commonImpressionEvent() -> ImpressionEvent {
    var impression = ImpressionEvent()
    impression.clientLogTimestamp = MetricsTimestamp()
    impression.sessionID = sessionID
    return impression
  }
  
  public func commonClickEvent() -> ClickEvent {
    var click = ClickEvent()
    click.clientLogTimestamp = MetricsTimestamp()
    click.sessionID = sessionID
    return click
  }
  
  public func log(event: LogMessage) {
    events.append(event)
  }

  public func batchLogMessage(events: [LogMessage]) -> LogMessage? {
    return nil
  }

  @objc public func flush() {
    guard let batchMessage = batchLogMessage(events: events) else { return }
    events.removeAll()
    let url = URL(string: "http://localhost:8080/hello")!
    var request = URLRequest(url: url)
    do {
      let messageData = try batchMessage.serializedData()
      request.httpBody = messageData
      let fetcher = fetcherService.fetcher(with: request)
      fetcher.beginFetch { (data, error) in
        guard error == nil else {
          print("ERROR: \(error.debugDescription)")
          return
        }
        print("Fetch finished: \(String(describing: data))")
      }
    } catch BinaryEncodingError.missingRequiredFields {
      print("ERROR: Missing required fields.")
    } catch BinaryEncodingError.anyTranscodeFailure {
      print("ERROR: Any transcode failed.")
    } catch {
      print("ERROR: Error serializing protobuf.")
    }
  }
}

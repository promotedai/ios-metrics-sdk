import Foundation
import GTMSessionFetcherCore
import Schema
import SwiftProtobuf

@objc(PAMetricsLogger)
public class MetricsLogger: NSObject {
  private var fetcherService: GTMSessionFetcherService
  private var events: [SwiftProtobuf.Message]
  
  init(fetcherService: GTMSessionFetcherService = GTMSessionFetcherService()) {
    self.fetcherService = fetcherService
    self.events = []
  }
  
  func logSessionStart() {
    var event = Event_Session()
    event.platformID = 0
    event.logUserID = "logUserID"
    event.clientLogTimestamp = UInt64(Date().timeIntervalSince1970 * 1000)
    event.sessionID = "sessionID"
    events.append(event)
  }

  func flush() {
    let url = URL(string: "http://localhost:8081/foo")!
    var request = URLRequest(url: url)
    let fetcher = fetcherService.fetcher(with: request)
  }
}

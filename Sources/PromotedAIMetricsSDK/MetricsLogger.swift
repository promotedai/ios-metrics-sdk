import Foundation
import GTMSessionFetcherCore
import Protobuf
import SchemaObjC

@objc(PAMetricsLogger)
public class MetricsLogger: NSObject {
  public var customizer: MetricsCustomizer
  
  private var fetcherService: GTMSessionFetcherService
  private var events: [GPBMessage]
  
  init(customizer: MetricsCustomizer,
       fetcherService: GTMSessionFetcherService = GTMSessionFetcherService()) {
    self.fetcherService = fetcherService
    self.customizer = customizer
    self.events = []
  }
  
  func logSessionStart() {
    var session = PSESession()
    session.platformId = 0
    session.logUserId = "logUserID"
    session.clientLogTimestamp = MetricsTimestamp()
    session.sessionId = "sessionID"
    let customizedSession = customizer.sessionStartMessage(commonMessage: session)
    events.append(customizedSession)
  }
  
  func logImpression() {
    var impression = PSEImpression()
    impression.clientLogTimestamp = MetricsTimestamp()
    let customizedImpression = customizer.impressionMessage(commonMessage: impression)
    events.append(customizedImpression)
  }

  func flush() {
    let batchMessage = customizer.batchLogMessage(contents: events)
    events.removeAll()
    let url = URL(string: "http://localhost:8080/hello")!
    var request = URLRequest(url: url)
    let messageData = batchMessage.data()
    request.httpBody = messageData
    let fetcher = fetcherService.fetcher(with: request)
    fetcher.beginFetch { (data, error) in
      guard error == nil else {
        print("ERROR: \(error.debugDescription)")
        return
      }
      print("Fetch finished: \(String(describing: data))")
    }
  }
}

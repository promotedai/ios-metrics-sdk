import Foundation
import GTMSessionFetcherCore
import Protobuf
import SchemaObjC

@objc(PAMetricsLogger)
public class MetricsLogger: NSObject {
  public var customizer: MetricsCustomizer
  
  private var fetcherService: GTMSessionFetcherService
  private var events: [GPBMessage]
  
  private var logUserID: String
  private var sessionID: String
  
  init(customizer: MetricsCustomizer,
       fetcherService: GTMSessionFetcherService = GTMSessionFetcherService()) {
    self.fetcherService = fetcherService
    self.customizer = customizer
    self.events = []
    self.logUserID = "logUserID"
    self.sessionID = "sessionID"
  }
  
  func logSessionStart(clientMessage: GPBMessage? = nil) {
    var commonSession = PSESession()
    ProtobufSilenceVarWarning(&commonSession)

    commonSession.clientLogTimestamp = MetricsTimestamp()
    commonSession.logUserId = logUserID
    commonSession.platformId = 0
    commonSession.sessionId = sessionID

    let session = customizer.sessionStartMessage(commonMessage: commonSession, clientMessage: clientMessage)
    events.append(session)
  }

  func logImpression(clientMessage: GPBMessage? = nil) {
    var commonImpression = PSEImpression()
    ProtobufSilenceVarWarning(&commonImpression)

    commonImpression.clientLogTimestamp = MetricsTimestamp()
    commonImpression.sessionId = sessionID

    let impression = customizer.impressionMessage(commonMessage: commonImpression, clientMessage: clientMessage)
    events.append(impression)
  }
  
  func logClick(clientMessage: GPBMessage? = nil) {
    var commonClick = PSEClick()
    ProtobufSilenceVarWarning(&commonClick)

    commonClick.clientLogTimestamp = MetricsTimestamp()
    commonClick.sessionId = sessionID

    let click = customizer.clickMessage(commonMessage: commonClick, clientMessage: clientMessage)
    events.append(click)
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

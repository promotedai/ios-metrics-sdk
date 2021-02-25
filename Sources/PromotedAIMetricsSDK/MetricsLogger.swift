import Foundation
import SwiftProtobuf

#if canImport(GTMSessionFetcherCore)
import GTMSessionFetcherCore
#elseif canImport(GTMSessionFetcher)
import GTMSessionFetcher
#else
#error("Can't import GTMSessionFetcher")
#endif

#if canImport(SchemaProtosSwift)
import SchemaProtosSwift
#endif

public class MetricsLogger: NSObject {
  public var customizer: MetricsCustomizer
  
  private var fetcherService: GTMSessionFetcherService
  private var events: [Message]
  
  private var logUserID: String
  private var sessionID: String
  
  public init(customizer: MetricsCustomizer,
              fetcherService: GTMSessionFetcherService = GTMSessionFetcherService()) {
    self.fetcherService = fetcherService
    self.customizer = customizer
    self.events = []
    self.logUserID = "logUserID"
    self.sessionID = "sessionID"
  }
  
  public func logSessionStart(clientMessage: Message? = nil) {
    var commonSession = Event_Session()

    commonSession.clientLogTimestamp = MetricsTimestamp()
    commonSession.logUserID = logUserID
    commonSession.platformID = 0
    commonSession.sessionID = sessionID

    let session = customizer.sessionStartMessage(commonMessage: commonSession, clientMessage: clientMessage)
    events.append(session)
  }

  public func logImpression(clientMessage: Message? = nil) {
    var commonImpression = Event_Impression()

    commonImpression.clientLogTimestamp = MetricsTimestamp()
    commonImpression.sessionID = sessionID

    let impression = customizer.impressionMessage(commonMessage: commonImpression, clientMessage: clientMessage)
    events.append(impression)
  }
  
  public func logClick(clientMessage: Message? = nil) {
    var commonClick = Event_Click()

    commonClick.clientLogTimestamp = MetricsTimestamp()
    commonClick.sessionID = sessionID

    let click = customizer.clickMessage(commonMessage: commonClick, clientMessage: clientMessage)
    events.append(click)
  }

  public func flush() {
    let batchMessage = customizer.batchLogMessage(contents: events)
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
      print("ERROR: Unknown error serializing protobuf.")
    }
  }
}

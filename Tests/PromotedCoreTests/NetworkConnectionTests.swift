import Foundation
import SwiftProtobuf
import XCTest

@testable import PromotedCore
@testable import PromotedCoreTestHelpers

final class NetworkConnectionTests: ModuleTestCase {

  func testBodyDataJSON() {
    var message = Event_Action()
    message.actionID = "foo"
    
    do {
      config.metricsLoggingWireFormat = .json
      let jsonData = try connection.bodyData(message: message, clientConfig: config)
      let jsonString = String(data: jsonData, encoding: .utf8)!
      XCTAssertEqual("{\"actionId\":\"foo\"}", jsonString)
    } catch {
      XCTFail("JSON serialization threw an exception.")
    }
  }
  
  func testBodyDataBinary() {
    var message = Event_Action()
    message.actionID = "foo"
    
    do {
      config.metricsLoggingWireFormat = .binary
      let binaryData = try connection.bodyData(message: message, clientConfig: config)
      XCTAssertGreaterThan(binaryData.count, 0)
    } catch {
      XCTFail("Binary serialization threw an exception.")
    }
  }
    
  func testURLRequestAPIKey() {
    config.devMetricsLoggingAPIKey = "key!"
    config.metricsLoggingAPIKey = config.devMetricsLoggingAPIKey
    let url = URL(string: "http://promoted.ai")!
    let data = "foobar".data(using: .utf8)!
    let request = connection.urlRequest(url: url, data: data, clientConfig: config)
    XCTAssertEqual("key!", request.allHTTPHeaderFields!["x-api-key"]!)
  }
}

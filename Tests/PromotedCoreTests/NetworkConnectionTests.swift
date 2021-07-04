import Foundation
import SwiftProtobuf
import XCTest

@testable import PromotedCore
@testable import PromotedCoreTestHelpers

final class NetworkConnectionTests: ModuleTestCase {

  func testMetricsLoggingURL() {
    var config = ClientConfig()
    config.metricsLoggingURL = "http://fake.promoted.ai/prod"
    do {
      let url = try connection.metricsLoggingURL(clientConfig: config)
      XCTAssertEqual(config.metricsLoggingURL, url.absoluteString)
    } catch {
      XCTFail("URL generation threw an error: \(error)")
    }
    #if DEBUG
    config.devMetricsLoggingURL = "http://fake.promoted.ai/dev"
    do {
      let url = try connection.metricsLoggingURL(clientConfig: config)
      XCTAssertEqual(config.devMetricsLoggingURL, url.absoluteString)
    } catch {
      XCTFail("URL generation threw an error: \(error)")
    }
    #endif
  }

  func testBodyDataJSON() {
    var message = Event_Action()
    message.actionID = "foo"
    
    do {
      var config = ClientConfig()
      config.metricsLoggingWireFormat = .json
      let jsonData = try connection.bodyData(message: message, clientConfig: config)
      let jsonString = String(data: jsonData, encoding: .utf8)!
      XCTAssertEqual("{\"actionId\":\"foo\"}", jsonString)
    } catch {
      XCTFail("JSON serialization threw an error: \(error)")
    }
  }
  
  func testBodyDataBinary() {
    var message = Event_Action()
    message.actionID = "foo"
    
    do {
      var config = ClientConfig()
      config.metricsLoggingWireFormat = .binary
      let binaryData = try connection.bodyData(message: message, clientConfig: config)
      XCTAssertGreaterThan(binaryData.count, 0)
    } catch {
      XCTFail("Binary serialization threw an error: \(error)")
    }
  }
    
  func testURLRequestAPIKey() {
    var config = ClientConfig()
    config.metricsLoggingAPIKey = "key!"
    config.apiKeyHTTPHeaderField = "API_KEY"
    let url = URL(string: "http://promoted.ai")!
    let data = "foobar".data(using: .utf8)!
    do {
      let request = try connection.urlRequest(url: url, data: data, clientConfig: config)
      XCTAssertEqual("key!", request.allHTTPHeaderFields!["API_KEY"]!)
    } catch {
      XCTFail("URL request threw an error: \(error)")
    }
    #if DEBUG
    config.devMetricsLoggingAPIKey = "devkey!"
    do {
      let request = try connection.urlRequest(url: url, data: data, clientConfig: config)
      XCTAssertEqual("devkey!", request.allHTTPHeaderFields!["API_KEY"]!)
    } catch {
      XCTFail("URL request threw an error: \(error)")
    }
    #endif
  }
}

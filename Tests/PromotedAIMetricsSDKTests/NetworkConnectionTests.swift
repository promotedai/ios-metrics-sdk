import Foundation
import SwiftProtobuf
import XCTest

@testable import PromotedAIMetricsSDK

final class NetworkConnectionTests: XCTestCase {
  
  private var config: ClientConfig?
  private var connection: FakeNetworkConnection?

  public override func setUp() {
    super.setUp()
    config = ClientConfig()
    connection = FakeNetworkConnection()
  }
  
  func testBodyDataJSON() {
    var message = Event_Click()
    message.clickID = "foo"
    
    do {
      config?.metricsLoggingWireFormat = .json
      let jsonData = try connection!.bodyData(message: message, clientConfig: config!)
      let jsonString = String(data: jsonData, encoding: .utf8)!
      XCTAssertEqual("{\"clickId\":\"foo\"}", jsonString)
    } catch {
      XCTFail("JSON serialization threw an exception.")
    }
  }
  
  func testBodyDataBinary() {
    var message = Event_Click()
    message.clickID = "foo"
    
    do {
      config?.metricsLoggingWireFormat = .binary
      let binaryData = try connection!.bodyData(message: message, clientConfig: config!)
      XCTAssertGreaterThan(binaryData.count, 0)
    } catch {
      XCTFail("Binary serialization threw an exception.")
    }
  }
  
  func testBodyDataBase64EncodedBinary() {
    var message = Event_Click()
    message.clickID = "foo"
    
    do {
      config?.metricsLoggingWireFormat = .base64EncodedBinary
      let binaryData = try connection!.bodyData(message: message, clientConfig: config!)
      XCTAssertGreaterThan(binaryData.count, 0)
    } catch {
      XCTFail("Binary serialization threw an exception.")
    }
  }
  
  static var allTests = [
    ("testBodyDataJSON", testBodyDataJSON),
    ("testBodyDataBinary", testBodyDataBinary),
    ("testBodyDataBase64EncodedBinary", testBodyDataBase64EncodedBinary),
  ]
}

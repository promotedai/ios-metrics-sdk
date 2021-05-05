import Foundation

@testable import PromotedCore

final class FakeDeviceInfo: DeviceInfo {

  var deviceType: DeviceType {
    return .mobile
  }

  var brand: String {
    return "Apple"
  }

  var manufacturer: String {
    return "Apple"
  }
  
  var identifier: String {
    return "iPhone"
  }

  var osVersion: String {
    return "14.4.1"
  }
  
  var screenScale: Float {
    return 2.0
  }

  var screenSizePx: (UInt32, UInt32) {
    return (1024, 768)
  }
  
  var languageCode: String {
    return "en"
  }
  
  var regionCode: String {
    return "US"
  }
}

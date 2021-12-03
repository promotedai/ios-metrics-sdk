import Foundation

@testable import PromotedCore

final class FakeDeviceInfo: DeviceInfo {

  // `platform_app_version` and `promoted_mobile_sdk_version`
  // come from FakeBuildInfo.
  static let json = """
    "device": {
      "device_type": "MOBILE",
      "brand": "Apple",
      "manufacturer": "Apple",
      "identifier": "iPhone",
      "os_version": "14.4.1",
      "platform_app_version": "3.1.4",
      "promoted_mobile_sdk_version": "1.0.99",
      "screen": {
        "size": {
          "width": 1024,
          "height": 768
        },
        "scale": 2.0
      }
    }
    """

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

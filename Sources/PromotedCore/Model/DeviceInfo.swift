import Foundation

// MARK: - DeviceInfo
protocol DeviceInfo: AnyObject {
  var deviceType: DeviceType { get }
  var brand: String { get }
  var manufacturer: String { get }
  var identifier: String { get }
  var osVersion: String { get }
  var screenScale: Float { get }
  var screenSizePx: (UInt32, UInt32) { get }
  var languageCode: String { get }
  var regionCode: String { get }
}

protocol DeviceInfoSource: NoDeps {
  var deviceInfo: DeviceInfo { get }
}

// MARK: - iOS
import UIKit

/** Device info for iPhones and iPads. */
final class IOSDeviceInfo: DeviceInfo {

  var deviceType: DeviceType {
    switch UIDevice.current.userInterfaceIdiom {
    case .pad:
      return .tablet
    case .phone:
      return .mobile
    default:
      return .unknown
    }
  }

  var brand: String { "Apple" }
  
  var manufacturer: String { "Apple" }
  
  lazy var identifier: String = {
    var systemInfo = utsname()
    uname(&systemInfo)
    let machineMirror = Mirror(reflecting: systemInfo.machine)
    let identifier = machineMirror.children.reduce("") { identifier, element in
      guard let value = element.value as? Int8, value != 0 else { return identifier }
      return identifier + String(UnicodeScalar(UInt8(value)))
    }
    return identifier
  } ()
  
  var osVersion: String { UIDevice.current.systemVersion }

  var screenScale: Float { Float(UIScreen.main.scale) }

  var screenSizePx: (UInt32, UInt32) {
    let bounds = UIScreen.main.nativeBounds
    return (UInt32(bounds.width), UInt32(bounds.height))
  }
  
  var languageCode: String { Locale.current.languageCode ?? "unknown" }
  
  var regionCode: String { Locale.current.regionCode ?? "unknown" }
}

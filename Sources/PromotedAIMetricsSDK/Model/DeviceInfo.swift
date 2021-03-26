import Foundation

// MARK: - DeviceInfo
public protocol DeviceInfo {
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

func CurrentDeviceInfo() -> DeviceInfo {
  #if os(iOS)
    return IOSDeviceInfo()
  #elseif os(macOS)
    return MacOSDeviceInfo()
  #endif
}

// MARK: - iOS
#if os(iOS)
import UIKit

/** Device info for iPhones and iPads. */
class IOSDeviceInfo: DeviceInfo {

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

  var brand: String {
    return "Apple"
  }
  
  var manufacturer: String {
    return "Apple"
  }
  
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
  
  var osVersion: String {
    return UIDevice.current.systemVersion
  }

  var screenScale: Float {
    return UIScreen.main.scale
  }

  var screenSizePx: (UInt32, UInt32) {
    let bounds = UIScreen.main.nativeBounds
    return (UInt32(bounds.width), UInt32(bounds.height))
  }
  
  var languageCode: String {
    return Locale.current.languageCode
  }
  
  var regionCode: String {
    return Locale.current.regionCode
  }
}

// MARK: - macOS
#elseif os(macOS)

/** This is only used to compile on macOS. */
class MacOSDeviceInfo: DeviceInfo {

  var deviceType: DeviceType {
    return .desktop
  }

  var brand: String {
    return "Apple"
  }

  var manufacturer: String {
    return "Apple"
  }
  
  var identifier: String {
    return "Mac"
  }

  var osVersion: String {
    return "10.15"
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

#endif
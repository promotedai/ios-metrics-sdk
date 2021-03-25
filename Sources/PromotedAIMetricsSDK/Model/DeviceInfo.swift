import Foundation

// MARK: - DeviceInfo
protocol DeviceInfo {
  var deviceType: DeviceType { get }
  var brand: String { get }
  var deviceName: String { get }
  var display: String { get }
  var model: String { get }
  var screenSizePts: (UInt32, UInt32) { get }
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

  var deviceName: String {
    return UIDevice.current.model
  }
  
  var display: String {
    return UIDevice.current.systemVersion
  }
  
  lazy var model: String = {
    var systemInfo = utsname()
    uname(&systemInfo)
    let machineMirror = Mirror(reflecting: systemInfo.machine)
    let identifier = machineMirror.children.reduce("") { identifier, element in
      guard let value = element.value as? Int8, value != 0 else { return identifier }
      return identifier + String(UnicodeScalar(UInt8(value)))
    }
    return identifier
  } ()

  var screenSizePts: (UInt32, UInt32) {
    let bounds = UIScreen.main.bounds
    return (UInt32(bounds.width), UInt32(bounds.height))
  }
}

// MARK: - macOS
#elseif os(macOS)

class MacOSDeviceInfo: DeviceInfo {

  var deviceType: DeviceType {
    return .desktop
  }

  var brand: String {
    return "Apple"
  }

  var deviceName: String {
    return "Mac"
  }
  
  var display: String {
    return "11.1"
  }
  
  var model: String {
    return "Mac"
  }

  var screenSizePts: (UInt32, UInt32) {
    return (1024, 768)
  }
}

#endif

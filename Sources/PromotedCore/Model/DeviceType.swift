import Foundation

/** Type of user device. Wraps `Common_DeviceType`. */
enum DeviceType: Int {
  case unknown = 0
  case desktop = 1
  case mobile = 2
  case tablet = 3
}

extension DeviceType {
  var protoValue: Common_DeviceType {
    Common_DeviceType(rawValue: self.rawValue) ?? .unknownDeviceType
  }
}

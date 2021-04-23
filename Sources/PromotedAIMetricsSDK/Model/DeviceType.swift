import Foundation

public enum DeviceType: Int {
  case unknown = 0
  case desktop = 1
  case mobile = 2
  case tablet = 3
  
  var protoValue: Event_DeviceType? { Event_DeviceType(rawValue: self.rawValue) }
}

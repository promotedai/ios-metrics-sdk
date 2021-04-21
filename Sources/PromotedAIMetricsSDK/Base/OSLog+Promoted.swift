import Foundation
import os.log

extension OSLog {
  func signpostBegin(name: StaticString) {
    if #available(iOS 12.0, *) {
      os_signpost(.begin, log: self, name: name)
    }
  }
  
  func signpostEvent(name: StaticString,
                     format: StaticString = "",
                     _ arg0: CVarArg = "",
                     _ arg1: CVarArg = "",
                     _ arg2: CVarArg = "",
                     _ arg3: CVarArg = "") {
    if #available(iOS 12.0, *) {
      os_signpost(.event, log: self, name: name, format, arg0, arg1, arg2, arg3)
    }
  }
  
  func signpostEnd(name: StaticString) {
    if #available(iOS 12.0, *) {
      os_signpost(.end, log: self, name: name)
    }
  }
}

extension OSLog {
  func info(_ message: StaticString,
            _ arg0: CVarArg = "",
            _ arg1: CVarArg = "",
            _ arg2: CVarArg = "",
            _ arg3: CVarArg = "") {
    os_log(message, log: self, type: .info, arg0, arg1, arg2, arg3)
  }

  func debug(_ message: StaticString,
             _ arg0: CVarArg = "",
             _ arg1: CVarArg = "",
             _ arg2: CVarArg = "",
             _ arg3: CVarArg = "") {
    os_log(message, log: self, type: .debug, arg0, arg1, arg2, arg3)
  }

  func error(_ message: StaticString,
             _ arg0: CVarArg = "",
             _ arg1: CVarArg = "",
             _ arg2: CVarArg = "",
             _ arg3: CVarArg = "") {
    os_log(message, log: self, type: .error, arg0, arg1, arg2, arg3)
  }
}

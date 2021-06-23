import Foundation
import os.log

protocol OSLogSource {
  /// Callers own the returned object.
  func osLog(category: String) -> OSLog?
}

class SystemOSLogSource: OSLogSource {

  fileprivate weak static var sharedClientConfig: ClientConfig?

  typealias Deps = ClientConfigSource

  init(deps: Deps) {
    Self.sharedClientConfig = deps.clientConfig
  }

  func osLog(category: String) -> OSLog? {
    OSLog(subsystem: "ai.promoted", category: category)
  }
}

extension OSLog {
  func signpostBegin(name: StaticString) {
    if #available(iOS 12.0, *) {
      guard shouldLog(.info) else { return }
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
      guard shouldLog(.info) else { return }
      os_signpost(.event, log: self, name: name, format, arg0, arg1, arg2, arg3)
    }
  }
  
  func signpostEnd(name: StaticString) {
    if #available(iOS 12.0, *) {
      guard shouldLog(.info) else { return }
      os_signpost(.end, log: self, name: name)
    }
  }
}

extension OSLog {
  func error(_ message: StaticString,
             _ arg0: CVarArg = "",
             _ arg1: CVarArg = "",
             _ arg2: CVarArg = "",
             _ arg3: CVarArg = "") {
    guard shouldLog(.error) else { return }
    os_log(message, log: self, type: .error, arg0, arg1, arg2, arg3)
  }

  func warning(_ message: StaticString,
               _ arg0: CVarArg = "",
               _ arg1: CVarArg = "",
               _ arg2: CVarArg = "",
               _ arg3: CVarArg = "") {
    guard shouldLog(.warning) else { return }
    os_log(message, log: self, type: .error, arg0, arg1, arg2, arg3)
  }

  func debug(_ message: StaticString,
             _ arg0: CVarArg = "",
             _ arg1: CVarArg = "",
             _ arg2: CVarArg = "",
             _ arg3: CVarArg = "") {
    guard shouldLog(.debug) else { return }
    os_log(message, log: self, type: .debug, arg0, arg1, arg2, arg3)
  }

  func info(_ message: StaticString,
            _ arg0: CVarArg = "",
            _ arg1: CVarArg = "",
            _ arg2: CVarArg = "",
            _ arg3: CVarArg = "") {
    guard shouldLog(.info) else { return }
    os_log(message, log: self, type: .info, arg0, arg1, arg2, arg3)
  }
}

extension OSLog {
  func error(_ formatter: TabularLogFormatter) {
    guard shouldLog(.error) else { return }
    os_log("%{private}s", log: self, type: .error, formatter.asNewlineJoinedString())
  }

  func warning(_ formatter: TabularLogFormatter) {
    guard shouldLog(.warning) else { return }
    os_log("%{private}s", log: self, type: .error, formatter.asNewlineJoinedString())
  }

  func debug(_ formatter: TabularLogFormatter) {
    guard shouldLog(.debug) else { return }
    os_log("%{private}s", log: self, type: .debug, formatter.asNewlineJoinedString())
  }

  func info(_ formatter: TabularLogFormatter) {
    guard shouldLog(.info) else { return }
    os_log("%{private}s", log: self, type: .info, formatter.asNewlineJoinedString())
  }
}

fileprivate extension OSLog {
  func shouldLog(_ level: ClientConfig.OSLogLevel) -> Bool {
    guard let config = SystemOSLogSource.sharedClientConfig else {
      return false
    }
    return config.osLogLevel >= level
  }
}

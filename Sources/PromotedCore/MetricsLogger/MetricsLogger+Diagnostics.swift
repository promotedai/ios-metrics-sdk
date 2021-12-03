import Foundation
import SwiftProtobuf
import UIKit
import os.log

extension MetricsLogger {

  struct AncestorIDHistory {
    fileprivate typealias IDHistoryDeque = Deque<Event_AncestorIdHistoryItem>

    fileprivate var logUserIDs: IDHistoryDeque
    fileprivate var sessionIDs: IDHistoryDeque
    fileprivate var viewIDs: IDHistoryDeque
    fileprivate var autoViewIDs: IDHistoryDeque

    fileprivate unowned let osLog: OSLog?
    fileprivate unowned let xray: Xray?
  }

  func diagnosticsMessage(xray: Xray?) -> Event_Diagnostics? {
    guard config.anyDiagnosticsEnabled else { return nil }
    var mobileDiagnostics = mobileDiagnosticsMessage()
    if config.diagnosticsIncludeBatchSummaries, let xray = xray {
      fillBatchSummaries(in: &mobileDiagnostics, xray: xray)
    }
    if config.diagnosticsIncludeAncestorIDHistory {
      fillAncestorIDHistory(in: &mobileDiagnostics)
    }
    var diagnostics = Event_Diagnostics()
    diagnostics.timing = timingMessage()
    diagnostics.mobileDiagnostics = mobileDiagnostics
    return diagnostics
  }

  private func mobileDiagnosticsMessage() -> Event_MobileDiagnostics {
    var diagnostics = Event_MobileDiagnostics()
    if let id = UIDevice.current.identifierForVendor?.uuidString {
      diagnostics.deviceIdentifier = id
    }
    return diagnostics
  }

  private func fillBatchSummaries(
    in diagnostics: inout Event_MobileDiagnostics,
    xray: Xray
  ) {
    diagnostics.batchesAttempted = Int32(xray.batchesAttempted)
    diagnostics.batchesSentSuccessfully = Int32(xray.batchesSentSuccessfully)
    diagnostics.batchesWithErrors = Int32(xray.batchesWithErrors)
    var errorHistory = Event_ErrorHistory()
    errorHistory.iosErrors = xray.networkBatches.flatMap { batch in
      batch.errorsAcrossCalls.map { error in
        let e = error.asErrorProperties()
        var errorProto = Event_IOSError()
        errorProto.code = Int32(e.code)
        errorProto.domain = e.domain
        errorProto.description_p = e.externalDescription
        errorProto.batchNumber = Int32(batch.batchNumber)
        return errorProto
      }
    }
    errorHistory.totalErrors = Int32(xray.totalErrors)
    diagnostics.errorHistory = errorHistory
  }

  private func fillAncestorIDHistory(
    in diagnostics: inout Event_MobileDiagnostics
  ) {
    guard let history = history else { return }
    var historyMessage = Event_AncestorIdHistory()
    historyMessage.logUserIDHistory = history.logUserIDs.values
    historyMessage.sessionIDHistory = history.sessionIDs.values
    historyMessage.viewIDHistory = history.viewIDs.values
    historyMessage.autoViewIDHistory = history.autoViewIDs.values
    diagnostics.ancestorIDHistory = historyMessage
  }
}

extension MetricsLogger.AncestorIDHistory {

  init(osLog: OSLog?, xray: Xray?) {
    self.osLog = osLog
    self.xray = xray
    let size = 10
    logUserIDs = IDHistoryDeque(maximumSize: size)
    sessionIDs = IDHistoryDeque(maximumSize: size)
    viewIDs = IDHistoryDeque(maximumSize: size)
    autoViewIDs = IDHistoryDeque(maximumSize: size)
  }

  mutating func logUserIDDidChange(value: String?, event: Message? = nil) {
    logUserIDs.ancestorIDDidChange(
      value: value,
      event: event,
      osLog: osLog,
      xray: xray
    )
  }

  mutating func sessionIDDidChange(value: String?) {
    sessionIDs.ancestorIDDidChange(
      value: value,
      event: nil,
      osLog: osLog,
      xray: xray
    )
  }

  mutating func viewIDDidChange(value: String?, event: Message? = nil) {
    viewIDs.ancestorIDDidChange(
      value: value,
      event: event,
      osLog: osLog,
      xray: xray
    )
  }

  mutating func autoViewIDDidChange(value: String?, event: Message? = nil) {
    autoViewIDs.ancestorIDDidChange(
      value: value,
      event: event,
      osLog: osLog,
      xray: xray
    )
  }
}

fileprivate extension Deque where Element == Event_AncestorIdHistoryItem {
  mutating func ancestorIDDidChange(
    value: String?,
    event: Message?,
    osLog: OSLog?,
    xray: Xray?
  ) {
    var historyItem = Event_AncestorIdHistoryItem()
    if let value = value {
      historyItem.ancestorID = value
    }
    if let event = event {
      switch event {
      case let user as Event_User:
        historyItem.userEvent = user
      case let view as Event_View:
        historyItem.viewEvent = view
      default:
        osLog?.warning(
          "ancestorIDDidChange: Unknown event: %{private}@",
          String(describing: event)
        )
      }
    }
    if let xray = xray {
      historyItem.batchNumber = Int32(xray.currentBatchNumber)
    }
    pushBack(historyItem)
  }
}

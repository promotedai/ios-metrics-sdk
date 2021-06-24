import Foundation
import SwiftProtobuf
import UIKit

extension MetricsLogger {

  func mobileDiagnosticsMessage() -> Event_MobileDiagnostics {
    var diagnostics = Event_MobileDiagnostics()
    diagnostics.timing = timingMessage()
    if let id = UIDevice.current.identifierForVendor?.uuidString {
      diagnostics.deviceIdentifier = id
    }
    let appVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") ?? "Unknown"
    let buildNumber = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") ?? "Unknown"
    diagnostics.clientVersion = "\(appVersion) \(buildNumber)"
    let promotedBundle = Bundle(for: MetricsLogger.self)
    let promotedVersion = promotedBundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "Unknown"
    diagnostics.promotedLibraryVersion = promotedVersion
    return diagnostics
  }

  func fillDiagnostics(in diagnostics: inout Event_MobileDiagnostics, xray: Xray) {
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
  }

  func fillAncestorIDHistory(in diagnostics: inout Event_MobileDiagnostics) {
    var history = Event_AncestorIdHistory()
    // TODO
    diagnostics.ancestorIDHistory = history
  }
}

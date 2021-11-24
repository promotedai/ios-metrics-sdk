import Foundation

extension MetricsLogger {
  func identifierProvenancesMessage(
    logUserID: ID = .null,
    sessionID: ID = .null,
    viewID: ID = .null,
    autoViewID: ID = .null,
    impressionID: ID = .null,
    actionID: ID = .null,
    contentID: ID = .null,
    requestID: ID = .null
  ) -> Event_IdentifierProvenances {
    var provenances = Event_IdentifierProvenances()
    provenances.userIDProvenance = logUserID.protoValue
    provenances.sessionIDProvenance = sessionID.protoValue
    provenances.viewIDProvenance = viewID.protoValue
    provenances.autoViewIDProvenance = autoViewID.protoValue
    provenances.impressionIDProvenance = impressionID.protoValue
    provenances.actionIDProvenance = actionID.protoValue
    provenances.contentIDProvenance = contentID.protoValue
    provenances.requestIDProvenance = requestID.protoValue
    return provenances
  }
}

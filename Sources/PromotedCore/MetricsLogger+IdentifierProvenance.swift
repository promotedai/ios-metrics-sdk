import Foundation

extension MetricsLogger {
  func identifierProvenancesMessage(
    logUserID: ID? = nil,
    sessionID: ID? = nil,
    viewID: ID? = nil,
    autoViewID: ID? = nil,
    impressionID: ID? = nil,
    actionID: ID? = nil,
    contentID: ID? = nil,
    requestID: ID? = nil
  ) -> Event_IdentifierProvenances {
    var provenances = Event_IdentifierProvenances()
    provenances.userIDProvenance = logUserID?.protoValue ?? .null
    provenances.sessionIDProvenance = sessionID?.protoValue ?? .null
    provenances.viewIDProvenance = viewID?.protoValue ?? .null
    provenances.autoViewIDProvenance = autoViewID?.protoValue ?? .null
    provenances.impressionIDProvenance = impressionID?.protoValue ?? .null
    provenances.actionIDProvenance = actionID?.protoValue ?? .null
    provenances.contentIDProvenance = contentID?.protoValue ?? .null
    provenances.requestIDProvenance = requestID?.protoValue ?? .null
    return provenances
  }
}

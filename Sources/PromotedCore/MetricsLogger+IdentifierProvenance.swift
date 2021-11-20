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
    if let p = logUserID?.protoValue {
      provenances.userIDProvenance = p
    }
    if let p = sessionID?.protoValue {
      provenances.sessionIDProvenance = p
    }
    if let p = viewID?.protoValue {
      provenances.viewIDProvenance = p
    }
    if let p = autoViewID?.protoValue {
      provenances.autoViewIDProvenance = p
    }
    if let p = impressionID?.protoValue {
      provenances.impressionIDProvenance = p
    }
    if let p = actionID?.protoValue {
      provenances.actionIDProvenance = p
    }
    if let p = contentID?.protoValue {
      provenances.contentIDProvenance = p
    }
    if let p = requestID?.protoValue {
      provenances.requestIDProvenance = p
    }
    return provenances
  }
}

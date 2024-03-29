import Foundation

extension MetricsLogger {

  /// Creates `IdentifierProvenances` diagnostics message
  /// when needed.
  ///
  /// - `userID` is always platform specified.
  /// - `logUserID` and `sessionID` always come from internal
  ///   `IDProducer`s and are therefore always autogenerated.
  ///
  /// - Parameters:
  ///   - config: Config for `MetricsLogger`.
  ///   - autoViewID: Always autogenerated. May come from React
  ///     Native Metrics, which still counts as autogenerated.
  ///   - impressionID: Always autogenerated. May come from
  ///     `ImpressionTracker`, which still counts as autogenerated.
  ///   - actionID: Always autogenerated.
  ///   - contentID: Always platform specified.
  ///   - requestID: Always platform specified, but currently
  ///     unused and subject to change.
  ///   - platformSpecifiedViewID: Platform specified ID passed
  ///     in to event logging methods. This can be used to set
  ///     the view ID state to match that of other analytics
  ///     trackers.
  ///   - internalViewID: Internal state of `ViewTracker`. May be
  ///     either autogenerated or platform specified, depending on
  ///     the last call to `logView`. Specified as a param here
  ///     because we don't want to fill out this field on the
  ///     `IdentifierProvenances` proto if the associated event
  ///     doesn't support `viewID`.
  func identifierProvenancesMessage(
    autoViewID: String? = nil,
    impressionID: ID = .null,
    actionID: ID = .null,
    contentID: String? = nil,
    insertionID: String? = nil,
    requestID: String? = nil,
    platformSpecifiedViewID: String? = nil,
    internalViewID: ID = .null
  ) -> Event_IdentifierProvenances? {
    guard config.eventsIncludeIDProvenances else { return nil }
    return identifierProvenancesMessage(
      userID: userID,
      logUserID: logUserIDProducer.currentValue,
      sessionID: sessionIDProducer.currentValue,
      viewID: (
        platformSpecifiedViewID != nil ?
          .idForPlatformSpecifiedString(platformSpecifiedViewID) :
          internalViewID
      ),
      autoViewID: .idForAutogeneratedString(autoViewID),
      impressionID: impressionID,
      actionID: actionID,
      contentID: .idForPlatformSpecifiedString(contentID),
      insertionID: .idForAutogeneratedString(insertionID),
      requestID: .idForPlatformSpecifiedString(requestID)
    )
  }

  private func identifierProvenancesMessage(
    userID: ID = .null,
    logUserID: ID = .null,
    sessionID: ID = .null,
    viewID: ID = .null,
    autoViewID: ID = .null,
    impressionID: ID = .null,
    actionID: ID = .null,
    contentID: ID = .null,
    insertionID: ID = .null,
    requestID: ID = .null
  ) -> Event_IdentifierProvenances {
    var provenances = Event_IdentifierProvenances()
    provenances.userIDProvenance = userID.protoValue
    provenances.logUserIDProvenance = logUserID.protoValue
    provenances.sessionIDProvenance = sessionID.protoValue
    provenances.viewIDProvenance = viewID.protoValue
    provenances.autoViewIDProvenance = autoViewID.protoValue
    provenances.impressionIDProvenance = impressionID.protoValue
    provenances.actionIDProvenance = actionID.protoValue
    provenances.contentIDProvenance = contentID.protoValue
    provenances.insertionIDProvenance = insertionID.protoValue
    provenances.requestIDProvenance = requestID.protoValue
    return provenances
  }
}

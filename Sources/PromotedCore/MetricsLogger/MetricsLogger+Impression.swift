import Foundation
import SwiftProtobuf

// MARK: - Impression Logging Methods (ObjC)

public extension MetricsLogger {

  /// Logs an impression for the given content.
  /// See also `ImpressionTracker` and `ScrollTracker` for more
  /// advanced impression tracking methods.
  @objc(logImpressionWithContent:)
  func _objcLogImpression(content: Content) {
    logImpression(content: content, sourceType: .unknown)
  }

  /// Logs an impression for the given content and source type.
  /// See also `ImpressionTracker` and `ScrollTracker` for more
  /// advanced impression tracking methods.
  @objc(logImpressionWithContent:sourceType:)
  func _objcLogImpression(
    content: Content,
    sourceType: ImpressionSourceType
  ) {
    logImpression(content: content, sourceType: sourceType)
  }
}

// MARK: - Impression Logging Methods (Swift)

public extension MetricsLogger {

  /// Logs an impression for the given content and source type.
  /// See also `ImpressionTracker` and `ScrollTracker` for more
  /// advanced impression tracking methods.
  @discardableResult
  func logImpression(
    content: Content,
    sourceType: ImpressionSourceType = .unknown,
    autoViewState: AutoViewState = .empty,
    viewID: String? = nil
  ) -> Event_Impression {
    return logImpression(
      sourceType: sourceType,
      autoViewState: autoViewState,
      contentID: content.contentID,
      insertionID: content.insertionID,
      viewID: viewID
    )
  }

  /// Logs an impression event.
  /// See also `ImpressionTracker` and `ScrollTracker` for more
  /// advanced impression tracking methods.
  ///
  /// Autogenerates the following fields:
  /// - `timing` from `clock.nowMillis`
  /// - `impressionID` from a combination of `insertionID`,
  ///    `contentID`, and `logUserID`
  /// - `sessionID` from state in this logger
  /// - `viewID` from state in this logger
  ///
  /// - Parameters:
  ///   - contentID: Content ID from which to derive `impressionID`
  ///   - insertionID: Insertion ID as provided by Promoted
  ///   - requestID: Request ID as provided by Promoted
  ///   - viewID: View ID to set in impression. If not provided, defaults to
  ///     the view ID last logged via `logView`.
  ///   - sourceType: Origin of the impressed content
  ///   - properties: Client-specific message
  /// - Returns:
  ///   Logged event message.
  @discardableResult
  func logImpression(
    sourceType: ImpressionSourceType? = nil,
    autoViewState: AutoViewState = .empty,
    contentID: String? = nil,
    insertionID: String? = nil,
    requestID: String? = nil,
    viewID: String? = nil,
    properties: Message? = nil
  ) -> Event_Impression {
    var impression = Event_Impression()
    withMonitoredExecution {
      impression.timing = timingMessage()
      let impressionID = idMap.impressionID()
      if let id = impressionID.stringValue { impression.impressionID = id }
      if let i = insertionID { impression.insertionID = i }
      if let r = requestID { impression.requestID = r }
      if let s = sessionID { impression.sessionID = s }
      if let v = viewID ?? self.viewID { impression.viewID = v }
      if let a = autoViewState.autoViewID { impression.autoViewID = a }
      if let c = contentID { impression.contentID = c }
      if let s = sourceType?.protoValue { impression.sourceType = s }
      if let h = autoViewState.hasSuperimposedViews {
        impression.hasSuperimposedViews_p = h
      }
      if let i = identifierProvenancesMessage(
        config: config,
        autoViewID: autoViewState.autoViewID,
        impressionID: impressionID,
        contentID: contentID,
        insertionID: insertionID,
        requestID: requestID,
        platformSpecifiedViewID: viewID,
        internalViewID: viewTracker.id.currentValue
      ) {
        impression.idProvenances = i
      }
      if let p = propertiesMessage(properties) { impression.properties = p }
      log(message: impression)
    }
    return impression
  }
}

import Foundation

@objc(PROClientConfig)
public final class _ObjCClientConfig: NSObject {

  @objc public var loggingEnabled: Bool = true

  @objc public var metricsLoggingURL: String = ""

  @objc public var devMetricsLoggingURL: String = ""

  @objc public var metricsLoggingAPIKey: String = ""

  @objc public var devMetricsLoggingAPIKey: String = ""

  @objc public var apiKeyHTTPHeaderField: String = "x-api-key"

  @objc public var metricsLoggingWireFormat:
    ClientConfig.MetricsLoggingWireFormat = .binary

  @objc public var loggingFlushInterval: TimeInterval = 10.0

  @objc public var flushLoggingOnResignActive: Bool = true

  @objc public var scrollTrackerVisibilityThreshold: Float = 0.5

  @objc public var scrollTrackerDurationThreshold: TimeInterval = 1.0

  @objc public var scrollTrackerUpdateFrequency: TimeInterval = 0.5

  @objc public var xrayLevel: ClientConfig.XrayLevel = .none

  @objc public var osLogLevel: ClientConfig.OSLogLevel = .none

  @objc public var diagnosticsIncludeBatchSummaries: Bool = false

  @objc public var diagnosticsIncludeAncestorIDHistory: Bool = false

  @objc public override init() {}
}

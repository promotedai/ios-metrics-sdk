import Foundation

/**
 Configuration for impression logging contexts.
 Methods contained herein modify and return `self`.
 */
@objc(PROImpressionConfig)
public protocol ImpressionConfig {

  /// Configures the impression logging context to use a
  /// given source type for all logged impressions.
  @objc(withSourceType:)
  @discardableResult
  func with(sourceType: ImpressionSourceType) -> Self
}

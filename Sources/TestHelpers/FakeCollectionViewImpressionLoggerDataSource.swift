import Foundation
import PromotedAIMetricsSDK

public class FakeCollectionViewImpressionLoggerDataSource:
    CollectionViewImpressionLoggerDataSource {
  public var indexPathsForVisibleItems: [IndexPath]
  public init(items: [IndexPath] = []) { indexPathsForVisibleItems = items }
}

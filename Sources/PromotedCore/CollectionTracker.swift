import Foundation
import UIKit

public class CollectionTracker {

  public typealias DataProducer = (IndexPath) -> Content?

  private unowned let metricsLogger: MetricsLogger
  private let impressionTracker: ImpressionTracker
  private unowned let collectionView: UICollectionView
  private let dataProducer: DataProducer

  private let visibilityThreshhold: Float = 0.5

  private var contentOffsetObservation: NSKeyValueObservation!
  private var gestureRecognizersObservation: NSKeyValueObservation!
  private var tapGestureRecognizer: UITapGestureRecognizer!

  public init(
    metricsLogger: MetricsLogger,
    impressionTracker: ImpressionTracker,
    collectionView: UICollectionView,
    dataProducer: @escaping DataProducer
  ) {
    self.metricsLogger = metricsLogger
    self.impressionTracker = impressionTracker
    self.collectionView = collectionView
    self.dataProducer = dataProducer

    addObserversToCollectionView()
  }
}

extension CollectionTracker {
  private func addObserversToCollectionView() {
    contentOffsetObservation = collectionView
      .observe(\.contentOffset) { [weak self] _, _ in
        self?.collectionViewDidScroll()
      }
    gestureRecognizersObservation = collectionView
      .observe(\.gestureRecognizers) { [weak self] _, _ in
        self?.collectionViewDidChangeGestureRecognizers()
      }
    tapGestureRecognizer = UITapGestureRecognizer(
      target: self,
      action: #selector(didTapCollectionView(sender:))
    )
    tapGestureRecognizer.cancelsTouchesInView = false
    collectionView.addGestureRecognizer(tapGestureRecognizer)
  }

  private func collectionViewDidScroll() {
    updateCellVisibility()
  }

  private func collectionViewDidChangeGestureRecognizers() {
    let recognizers = collectionView.gestureRecognizers ?? []
    if !recognizers.contains(tapGestureRecognizer) {
      print(
        "***** WARNING: CollectionTracker's UITapGestureRecognizer was removed."
      )
    }
  }

  @objc private func didTapCollectionView(sender: UITapGestureRecognizer) {
    guard
      let selectedPath = collectionView
        .indexPathForItem(at: sender.location(in: collectionView))
    else {
      print(
        "***** DEBUG: No index path at \(sender.location(in: collectionView))"
      )
      return
    }
    guard let content = dataProducer(selectedPath) else {
      print("***** WARNING: \(#function) no content for \(selectedPath)")
      return
    }
    print("***** logAction \(String(describing: content))")
    metricsLogger.logNavigateAction(content: content)
  }
}

extension CollectionTracker {
  private func updateCellVisibility() {
    let viewport = CGRect(
      origin: collectionView.contentOffset,
      size: collectionView.bounds.size
    )
    let layout = collectionView.collectionViewLayout
    let threshhold = visibilityThreshhold

    let contents = collectionView
      .indexPathsForVisibleItems
      .filter { path in
        (
          layout
            .layoutAttributesForItem(at: path)?
            .frame
            .overlapRatio(viewport) ?? 0
        ) > threshhold
      }
      .compactMap { path in dataProducer(path) }
    impressionTracker.collectionViewDidChangeVisibleContent(contents)
  }
}

@available(iOS 13.0, *)
public extension CollectionTracker {
  typealias ItemToContent<T> = (T?) -> Content?

  convenience init<S, T: Hashable>(
    metricsLogger: MetricsLogger,
    impressionTracker: ImpressionTracker,
    collectionView: UICollectionView,
    dataSource: UICollectionViewDiffableDataSource<S, T>,
    itemToContent: @escaping ItemToContent<T>
  ) {
    self.init(
      metricsLogger: metricsLogger,
      impressionTracker: impressionTracker,
      collectionView: collectionView
    ) { path in
      itemToContent(dataSource.itemIdentifier(for: path))
    }
  }
}

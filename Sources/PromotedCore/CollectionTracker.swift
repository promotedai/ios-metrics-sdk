import Foundation
import OSLog
import UIKit

public class CollectionTracker {

  public typealias DataProducer = (IndexPath) -> Content?

  private unowned let metricsLogger: MetricsLogger
  private let impressionTracker: ImpressionTracker
  private unowned let collectionView: UICollectionView
  private let osLog: OSLog?
  private let dataProducer: DataProducer

  private let visibilityThreshhold: Float = 0.5

  private var contentOffsetObservation: NSKeyValueObservation!
  private var gestureRecognizersObservation: NSKeyValueObservation!
  private var tapGestureRecognizer: UITapGestureRecognizer!

  typealias Deps = OSLogSource

  init(
    metricsLogger: MetricsLogger,
    impressionTracker: ImpressionTracker,
    collectionView: UICollectionView,
    deps: Deps,
    dataProducer: @escaping DataProducer
  ) {
    self.metricsLogger = metricsLogger
    self.impressionTracker = impressionTracker
    self.collectionView = collectionView
    self.osLog = deps.osLog(category: "CollectionTracker")
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
    tapGestureRecognizer = UITapGestureRecognizer(
      target: self,
      action: #selector(didTapCollectionView(sender:))
    )
    tapGestureRecognizer.cancelsTouchesInView = false
    collectionView.addGestureRecognizer(tapGestureRecognizer)
    gestureRecognizersObservation = collectionView
      .observe(\.gestureRecognizers) { [weak self] _, _ in
        self?.collectionViewDidChangeGestureRecognizers()
      }
  }

  private func collectionViewDidScroll() {
    updateCellVisibility()
  }

  private func collectionViewDidChangeGestureRecognizers() {
    let recognizers = collectionView.gestureRecognizers ?? []
    if !recognizers.contains(tapGestureRecognizer) {
      osLog?.warning("CollectionTracker's UITapGestureRecognizer was removed")
    }
  }

  @objc private func didTapCollectionView(sender: UITapGestureRecognizer) {
    guard
      let selectedPath = collectionView
        .indexPathForItem(at: sender.location(in: collectionView))
    else {
      osLog?.debug(
        "No index path at %{public}@",
        sender.location(in: collectionView)
      )
      return
    }
    guard let content = dataProducer(selectedPath) else {
      osLog.warning("No content for %{public}@", selectedPath)
      return
    }
    let impressionID = impressionTracker.impressionID(for: content)
    if impressionID == nil {
      osLog?.warning(
        "No impressionID for %{private}@",
        String(describing: content)
      )
    }
    osLog?.info(
      "Logging clickthrough for %{private}@",
      String(describing: content)
    )
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
      .filter { path in (
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

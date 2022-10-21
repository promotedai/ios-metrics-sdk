# Promoted.ai iOS Client Library
[Promoted.ai](http://promoted.ai) provides an iOS logging library for gathering metrics and training delivery systems. This library contains the functionality required to track events in your iOS app and deliver them efficiently to Promoted.ai backends.

Our client library is available for iOS 11+, and works with both Swift and Objective-C apps. We also support React Native apps with a separate package called [react-native-metrics](https://github.com/promotedai/react-native-metrics).

Special thanks to [Wendy Lu](https://www.linkedin.com/in/wendyluwho/) for expert review.

# App Privacy

Pursuant to [Apple's app privacy questions](https://developer.apple.com/app-store/app-privacy-details/), Promoted's logging library collects the following kinds of data:

- Search history (linked to user via account)[1]
- User ID (linked to user via account)
- Purchase history (linked to user via account)
- Product interaction (linked to user via account)
- Advertising data (linked to user via account)
- Crash data
- Performance data

This data is used for the following purposes:

- Developer’s advertising or marketing
- Analytics
- Product personalization
- App functionality

[1] This linkage can be easily broken if the user wants to be forgotten.

# Technology
Our client library is built on the following technologies:

1. Protocol Buffers: A data exchange format that is much more efficient over the wire than JSON, making our data usage much lower than JSON-based logging solutions.
1. GTMSessionFetcher (optional): A library for network access used by many Google iOS apps.
1. Firebase Analytics (optional): Provides monitoring of the client library in production traffic.
1. Firebase Remote Config (optional): Provides server-side configuration of the client library’s behavior without the need for an additional App Store review/release cycle.

Dependencies marked as (optional) are not installed unless you choose to include them. By default, we include GTMSessionFetcher, but you can provide your own network interface and exclude this dependency.

# Availability
Our client library is available via the following channels. You will receive instructions on how to integrate via the channel you choose.

1. As a Swift Package ([PromotedAIMetricsSDK](https://swiftpackageregistry.com/promotedai/ios-metrics-sdk))
1. As a Cocoapod ([PromotedAIMetricsSDK](https://github.com/promotedai/ios-metrics-sdk))
1. As an NPM package (React Native only) ( [react-native-metrics](https://github.com/promotedai/react-native-metrics))

# Integration
Your app controls the initialization and behavior of our client library through the following classes:

1. `MetricsLoggingService` configures the behavior and initialization of the library. 
1. `MetricsLogger` accepts log messages to send to the server. 
1. `ImpressionTracker` tracks impressions of content in a collection view.

## MetricsLoggerService
Create and configure the service when your app starts, then retrieve the `MetricsLogger` instance from the service after it has been configured. Alternatively, create `ImpressionTracker` instances using the service.

### Example usage (dependency injection)
```swift
var config = ClientConfig()
config.metricsLoggingURL = "https://yourdomain.ext.promoted.ai"
config.metricsLoggingAPIKey = "..."
let service = try MetricsLoggerService(initialConfig: config)
try service.startLoggingServices()
// Create and use objects from the service
let logger = service.metricsLogger
let impressionTracker = service.impressionTracker(sourceType: .delivery)
let scrollTracker = service.scrollTracker(collectionView: ...)
```

### Example usage (singleton)
```swift
// Call this first before accessing the instance.
var config = ClientConfig()
config.metricsLoggingURL = "https://yourdomain.ext.promoted.ai"
config.metricsLoggingAPIKey = "..."
try MetricsLoggerService.startServices(initialConfig: config)
let service = MetricsLoggerService.shared
// Create and use objects from the service
let logger = service.metricsLogger
let impressionTracker = service.impressionTracker(sourceType: .delivery)
let scrollTracker = service.scrollTracker(collectionView: ...)
```

### Proxy servers
You can use a proxy server URL in `ClientConfig.metricsLoggingURL`. If you do this, you can specify any non-empty string for `metricsLoggingAPIKey`, since your proxy would presumably forward the real API key to the Promoted Metrics service.

```swift
var config = ClientConfig()
config.metricsLoggingURL = "https://proxy.yourdomain.com"
config.metricsLoggingAPIKey = "unused"
let service = try MetricsLoggerService(initialConfig: config)
```

See `MetricsLoggerService.swift` class docs for full explanation.

## MetricsLogger
Promoted event logging interface. Use instances of `MetricsLogger` to log events to Promoted’s servers. Events are accumulated and sent in batches on a timer.

To start a logging session, first call `startSession(userID:)` or `startSessionSignedOut()` to set up the user ID and log user ID for the session. You can call either `startSession` method more than once to begin a new session with the given user ID.
 
Use `log(message:)` to enqueue an event for logging. When the batching timer fires, all events are delivered to the server via the `NetworkConnection`.

### Example
```swift
let logger = MetricsLogger(...)
// Sets userID and logUserID for subsequent log() calls.
logger.startSession(userID: myUserID)
// Log clicks, purchases, or other relevant events
logger.logAction(type: .navigate, content: clickedContent)
logger.logAction(type: .purchase, content: purchasedContent)
// Resets userID and logUserID.
logger.startSession(userID: secondUserID)
```

## ImpressionTracker
 Provides basic impression tracking across scrolling collection views, such as `UICollectionView` or `UITableView`. Works best with views that can provide fine-grained updates of visible cells, but can also be adapted to work with views that don't (see `ScrollTracker`).

### Example usage with UICollectionView
Clients should create an instance of `ImpressionTracker` and reference it in their view controller, then provide updates to the impression logger as the collection view scrolls or updates.
 
```swift
class MyViewController: UIViewController {
  var collectionView: UICollectionView
  var impressionTracker: ImpressionTracker

  init(...) {
    impressionTracker = metricsLoggerService.impressionTracker()
  }

  private func content(atIndexPath path: IndexPath) -> Content? {
    let item = path.item
    if item >= self.items.count { return nil }
    let myItemProperties = self.items[item]
    return Item(properties: myItemProperties)
  }

  func viewWillDisappear(_ animated: Bool) {
    impressionTracker.collectionViewDidHideAllContent()
  }

  func collectionView(
    _ collectionView: UICollectionView,
    willDisplay cell: UICollectionViewCell,
    forItemAt indexPath: IndexPath
  ) {
    if let content = content(atIndexPath: indexPath) {
      impressionTracker.collectionViewWillDisplay(content: content)
    }
  }
   
  func collectionView(
    _ collectionView: UICollectionView,
    didEndDisplaying cell: UICollectionViewCell,
    forItemAt indexPath: IndexPath
  ) {
    if let content = content(atIndexPath: indexPath) {
      impressionTracker.collectionViewDidHide(content: content)
    }
  }

  func reloadCollectionView() {
    self.collectionView.reloadData()
    let visibleContent = collectionView.indexPathsForVisibleItems.map {
      path in content(atIndexPath: path)
    };
    impressionTracker.collectionViewDidChangeVisibleContent(visibleContent)
  }
}
```

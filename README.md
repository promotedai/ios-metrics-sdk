# Promoted.ai iOS Client Library
Promoted.ai provides an iOS logging library for integration with iOS apps. This library contains the functionality required to track events in your iOS app and deliver them efficiently to Promoted.ai backends.

Our client library is available for iOS 11+, and works with both Swift and Objective C apps.

## Technology
Our client library is built on a number of proven technologies:

1. Protocol Buffers: A data exchange format that is much more efficient over the wire than JSON, making our data usage much lower than JSON-based logging solutions.
1. GTMSessionFetcher: A library for network access used by many Google iOS apps.
1. Firebase Remote Config (roadmap): Provides server-side configuration of the client library’s behavior without the need for an additional App Store review/release cycle.
1. gRPC (roadmap): A high-performance RPC framework used by many Google iOS apps.

## Availability
Our client library is available via the following channels. You will receive instructions on how to integrate via the channel you choose.

1. As a Swift Package.
1. As a Cocoapod.
1. As an NPM package (React Native only). See [react-native-metrics](https://github.com/promotedai/react-native-metrics).

## Integration
Your app controls the initialization and behavior of our client library through the following classes:

1. `MetricsLoggingService` configures the behavior and initialization of the library. 
1. `MetricsLogger` accepts log messages to send to the server. 
1. `ImpressionLogger` tracks impressions of content in a collection view.

### MetricsLoggerService
Initialization of the library is lightweight and mostly occurs in the background, and does not impact app startup performance.

Example usage (singleton):
~~~swift
// In your AppDelegate:
func application(_ application: UIApplication,
                 didFinishLaunchingWithOptions...) -> Bool {
  let config = ClientConfig()
  config.metricsLoggingURL = "..."
  config.metricsLoggingAPIKey = "..."
  MetricsLoggingService.startServices(initialConfig: config)
  let loggingService = MetricsLoggingService.sharedService
  self.logger = loggingService.metricsLogger
  return true
}
~~~

Example usage (dependency injection):
~~~swift
// In your AppDelegate:
func application(_ application: UIApplication,
                 didFinishLaunchingWithOptions...) -> Bool {
  let config = ClientConfig()
  config.metricsLoggingURL = "..."
  config.metricsLoggingAPIKey = "..."
  self.service = MetricsLoggingService(initialConfig: config)
  self.service.startLoggingServices()
  self.logger = service.metricsLogger
  return true
}
~~~

Handling user sign-in:
~~~swift
// Handling user sign-in/sign-out:
func userDidSignInWithID(_ userID: String) {
  self.logger.startSessionAndLogUser(userID: userID);
}

func userDidSignOut() {
  self.logger.startSessionAndLogSignedOutUser()
}
~~~

### MetricsLogger
`MetricsLogger` batches log messages to avoid wasteful network traffic that would affect battery life. It also provides hooks into the app’s life cycle to ensure delivery of client logs.

### ImpressionLogger
For `UICollectionViews` and other scroll views, we can track the appearance and disappearance of individual cells for fine-grained impression logging. We provide `ImpressionLogger`, a solution that hooks into most `UICollectionView`s and `UIViewController`s easily.

Example usage with UICollectionView:
~~~swift
class MyViewController: UIViewController {
  var collectionView: UICollectionView
  var impressionLogger: ImpressionLogger

  func viewWillDisappear(_ animated: Bool) {
    impressionLogger.collectionViewDidHideAllContent()
  }

  func collectionView(_ collectionView: UICollectionView,
                      willDisplay cell: UICollectionViewCell,
                      forItemAt indexPath: IndexPath) {
    let content = contentFor(indexPath: indexPath)
    impressionLogger.collectionViewWillDisplay(content: content)
  }
   
  func collectionView(_ collectionView: UICollectionView,
                      didEndDisplaying cell: UICollectionViewCell,
                      forItemAt indexPath: IndexPath) {
    let content = contentFor(indexPath: indexPath)
    impressionLogger.collectionViewDidHide(content: content)
  }

  func reloadCollectionView() {
    collectionView.reloadData()
    let visibleContent = collectionView.indexPathsForVisibleItems.map {
      contentFor(indexPath: $0)
    }
    impressionLogger.collectionViewDidChangeVisibleContent(visibleContent)
  }
}
~~~

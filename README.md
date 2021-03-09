# Promoted.ai iOS Client Library
Promoted.ai provides an iOS logging library for integration with iOS apps. This library contains the functionality required to track events in your iOS app and deliver them efficiently to Promoted.ai backends.

Our client library is available for iOS 12.4+, and works with both Swift and Objective C apps.

## Technology
Our client library is built on a number of proven technologies:

1. Protocol Buffers: A data exchange format that is much more efficient over the wire than JSON, making our data usage much lower than JSON-based logging solutions.
1. GTMSessionFetcher: A library for network access used by many Google iOS apps.
1. Firebase Remote Config (roadmap): Provides server-side configuration of the client library’s behavior without the need for an additional App Store review/release cycle.
1. gRPC (roadmap): A high-performance RPC framework used by many Google iOS apps.

## Availability
Our client library is available via the following channels. Access to this library is currently private. You will receive instructions on how to integrate via the channel you choose.

1. As a Swift Package.
1. As a Cocoapod.
1. As a framework.

## Integration
Your app controls the initialization and behavior of our client library through two main classes:

A LoggingService, which configures the behavior and initialization of the library. 
A Logger, which accepts log messages to send to the server. 

### LoggingService
Initialization of the library is lightweight and mostly occurs in the background, and does not impact app startup performance.

Example usage:
~~~
// In your AppDelegate:
- (BOOL)application:(UIApplication *)application 
    didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
  PROMetricsLoggingService *loggingService = PROMetricsLoggingService.sharedService;
  // If you use the services pattern or other kind of dependency injection,
  // you can also use [[PROMetricsLoggingService alloc] init] to create an
  // instance of LoggingService.
  [loggingService startLoggingServices];
  self.logger = loggingService.logger;
}

// Handling user sign-in/sign-out:
- (void)userDidSignInWithID:(NSString *)userID {
  [self.logger startSessionWithUserID:userID];
}

- (void)userDidSignOut {
  [self.logger startSessionSignedOut];
}
~~~

### Logger
Logger batches log messages to avoid wasteful network traffic that would affect battery life. It also provides hooks into the app’s life cycle to ensure delivery of client logs. The interface to Logger is minimally intrusive to your app’s code.

### Impression Logging Helper
For `UICollectionViews` and other scroll views, we can track the appearance and disappearance of individual cells for fine-grained impression logging. We provide `CollectionViewImpressionLogger`, a solution that hooks into most `UICollectionView`s and `UIViewController`s easily.

Example usage with UICollectionView:
~~~
@implementation MyViewController {
  UICollectionView *_collectionView;
  PROMetricsLogger *_logger;
  PROCollectionViewImpressionLogger *_impressionLogger;
}

- (void)viewWillDisappear:(BOOL)animated {
  [_impressionLogger collectionViewDidHideAllItems];
}

- (void)collectionView:(UICollectionView *)collectionView
       willDisplayCell:(UICollectionViewCell *)cell
    forItemAtIndexPath:(NSIndexPath *)indexPath {
  [_impressionLogger collectionViewWillDisplayItem:indexPath];
}
 
- (void)collectionView:(UICollectionView *)collectionView
  didEndDisplayingCell:(UICollectionViewCell *)cell
    forItemAtIndexPath:(NSIndexPath *)indexPath {
  [_impressionLogger collectionViewDidHideItem:indexPath];
}

- (void)reloadCollectionView {
  [_collectionView reloadData];
  NSArray<NSIndexPath *> *visibleItems = _collectionView.indexPathsForVisibleItems;
  [_impressionLogger collectionViewDidChangeWithVisibleItems:visibleItems];
}
~~~

// swift-tools-version:5.2

import PackageDescription

let package = Package(
  name: "PromotedAIMetricsSDK",
  platforms: [
    .macOS(.v10_15),
    .iOS(.v12)
  ],
  products: [
    .library(
      name: "PromotedAIMetricsSDK",
      targets: [
        "PromotedAIMetricsSDK",
        "RemoteConfig",
      ]),
    .library(
      name: "PromotedAIMetricsSDKCore",
      targets: [
        "PromotedAIMetricsSDK",
      ]),
    .library(
      name: "TestHelpers",
      targets: [
        "TestHelpers",
      ]),
  ],
  dependencies: [
    .package(name: "Firebase", url: "https://github.com/firebase/firebase-ios-sdk.git", from: "7.0.0"),
    .package(name: "GTMSessionFetcher", url: "https://github.com/google/gtm-session-fetcher", from: "1.5.0"),
    .package(name: "SwiftProtobuf", url: "https://github.com/apple/swift-protobuf", from: "1.15.0"),
  ],
  targets: [
    .target(
      name: "PromotedAIMetricsSDK",
      dependencies: [
        .product(name: "FirebaseRemoteConfig", package: "Firebase"),
        .product(name: "GTMSessionFetcherCore", package: "GTMSessionFetcher"),
        "SwiftProtobuf",
      ]),
    .target(
      name: "RemoteConfig",
      dependencies: [
        .product(name: "FirebaseRemoteConfig", package: "Firebase"),
        "PromotedAIMetricsSDK",
      ]),
    .target(
      name: "TestHelpers",
      dependencies: [
        "PromotedAIMetricsSDK",
      ]),
    .testTarget(
      name: "PromotedAIMetricsSDKTests",
      dependencies: [
        "PromotedAIMetricsSDK",
        "TestHelpers",
      ]),
  ]
)

// swift-tools-version:5.8

import PackageDescription

let package = Package(
  name: "PromotedAIMetricsSDK",
  platforms: [
    .iOS(.v16)
  ],
  products: [
    .library(
      name: "PromotedCore",
      targets: [
        "PromotedCore",
      ]),
    .library(
      name: "PromotedFetcher",
      targets: [
        "PromotedFetcher",
      ]),
    .library(
      name: "PromotedMetrics",
      targets: [
        "PromotedMetrics",
      ]),
    .library(
      name: "PromotedFirebaseAnalytics",
      targets: [
        "PromotedFirebaseAnalytics",
      ]),
    .library(
      name: "PromotedFirebaseRemoteConfig",
      targets: [
        "PromotedFirebaseRemoteConfig",
      ]),
  ],
  dependencies: [
    .package(url: "https://github.com/firebase/firebase-ios-sdk", from: "10.0.0"),
    .package(url: "https://github.com/google/gtm-session-fetcher", from: "3.0.0"),
    .package(url: "https://github.com/apple/swift-protobuf", from: "1.15.0"),
  ],
  targets: [
    .target(
      name: "PromotedCore",
      dependencies: [
        .product(name: "SwiftProtobuf", package: "swift-protobuf"),
      ],
      resources: [
        .copy("Resources/Version.txt"),
      ]),
    .target(
      name: "PromotedFetcher",
      dependencies: [
        .product(name: "GTMSessionFetcherCore", package: "gtm-session-fetcher"),
        .target(name: "PromotedCore"),
      ]),
    .target(
      name: "PromotedFirebaseAnalytics",
      dependencies: [
        .product(name: "FirebaseAnalytics", package: "firebase-ios-sdk"),
        .target(name: "PromotedCore"),
      ]),
    .target(
      name: "PromotedFirebaseRemoteConfig",
      dependencies: [
        .product(name: "FirebaseRemoteConfig", package: "firebase-ios-sdk"),
        .target(name: "PromotedCore"),
      ]),
    .target(
      name: "PromotedMetrics",
      dependencies: [
        .target(name: "PromotedCore"),
        .target(name: "PromotedFetcher"),
      ]),
    .target(
      name: "PromotedCoreTestHelpers",
      dependencies: [
        .target(name: "PromotedCore"),
      ]),
    .testTarget(
      name: "PromotedCoreTests",
      dependencies: [
        .target(name: "PromotedCore"),
        .target(name: "PromotedCoreTestHelpers"),
      ]),
    .testTarget(
      name: "PromotedFirebaseRemoteConfigTests",
      dependencies: [
        .target(name: "PromotedCore"),
        .target(name: "PromotedCoreTestHelpers"),
        .target(name: "PromotedFirebaseRemoteConfig"),
      ]),
  ]
)

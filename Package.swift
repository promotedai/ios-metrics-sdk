// swift-tools-version:5.2

import PackageDescription

let package = Package(
  name: "PromotedAIMetricsSDK",
  platforms: [
    .iOS(.v12)
  ],
  products: [
    .library(
      name: "PromotedAIMetricsSDK",
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
    .package(name: "Firebase", url: "https://github.com/firebase/firebase-ios-sdk", from: "7.0.0"),
    .package(name: "GTMSessionFetcher", url: "https://github.com/google/gtm-session-fetcher", from: "1.5.0"),
    .package(name: "SwiftProtobuf", url: "https://github.com/apple/swift-protobuf", from: "1.15.0"),
  ],
  targets: [
    .target(
      name: "Fetcher",
      dependencies: [
        .product(name: "GTMSessionFetcherCore", package: "GTMSessionFetcher"),
        "PromotedAIMetricsSDK",
      ]),
    .target(
      name: "PromotedAIMetricsSDK",
      dependencies: [
        "SwiftProtobuf",
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

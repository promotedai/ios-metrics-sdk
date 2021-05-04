// swift-tools-version:5.2

import PackageDescription

let package = Package(
  name: "PromotedAIMetricsSDK",
  platforms: [
    .iOS(.v12)
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
  ],
  dependencies: [
    // .package(name: "Firebase", url: "https://github.com/firebase/firebase-ios-sdk", from: "7.0.0"),
    .package(name: "GTMSessionFetcher", url: "https://github.com/google/gtm-session-fetcher", from: "1.5.0"),
    .package(name: "SwiftProtobuf", url: "https://github.com/apple/swift-protobuf", from: "1.15.0"),
  ],
  targets: [
    .target(
      name: "PromotedCore",
      dependencies: [
        "SwiftProtobuf",
      ]),
    .target(
      name: "PromotedFetcher",
      dependencies: [
        .product(name: "GTMSessionFetcherCore", package: "GTMSessionFetcher"),
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
  ]
)

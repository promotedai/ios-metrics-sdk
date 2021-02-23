// swift-tools-version:5.3

import PackageDescription

let package = Package(
  name: "PromotedAIMetricsSDK",
  products: [
    .library(
      name: "PromotedAIMetricsSDK",
      targets: ["PromotedAIMetricsSDK"]),
  ],
  dependencies: [
    .package(name: "GTMSessionFetcher", url: "https://github.com/google/gtm-session-fetcher", from: "1.5.0"),
    .package(name: "PromotedAICommonSchema", path: "../../common-schema"),
    .package(name: "PromotedAISchema", path: "../../schema"),
    .package(name: "SwiftProtobuf", url: "https://github.com/apple/swift-protobuf", from: "1.15.0"),
  ],
  targets: [
    .target(
      name: "PromotedAIMetricsSDK",
      dependencies: [
        .product(name: "CommonSchema", package: "PromotedAICommonSchema"),
        .product(name: "GTMSessionFetcherCore", package: "GTMSessionFetcher"),
        .product(name: "Schema", package: "PromotedAISchema"),
        .product(name: "SwiftProtobuf", package: "SwiftProtobuf"),
      ]),
    .testTarget(
      name: "PromotedAIMetricsSDKTests",
      dependencies: ["PromotedAIMetricsSDK"]),
  ]
)

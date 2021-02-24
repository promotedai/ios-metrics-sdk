// swift-tools-version:5.3

import PackageDescription

let package = Package(
  name: "PromotedAIMetricsSDK",
  products: [
    .library(
      name: "PromotedAIMetricsSDK",
      targets: [
        "PromotedAIMetricsSDK",
      ]),
  ],
  dependencies: [
    .package(name: "GTMSessionFetcher", url: "https://github.com/google/gtm-session-fetcher", from: "1.5.0"),
    .package(name: "SwiftProtobuf", url: "https://github.com/apple/swift-protobuf", from: "1.15.0"),
  ],
  targets: [
    .target(
      name: "PromotedAIMetricsSDK",
      dependencies: [
        .product(name: "GTMSessionFetcherCore", package: "GTMSessionFetcher"),
        "SwiftProtobuf",
        "SchemaProtosSwift",
      ],
      exclude: [
        // Exclude the ObjC directory from SPM because we can't resolve the
        // ObjC Protobuf dependency in this system. Only the Cocoapod can
        // use ObjC Protobufs.
        "ObjC"
      ]),
    .testTarget(
      name: "PromotedAIMetricsSDKTests",
      dependencies: [
        "PromotedAIMetricsSDK"
      ]),
    .target(
      name: "SchemaProtosSwift",
      dependencies: [
        "SwiftProtobuf",
      ],
      path: "Sources/SchemaProtos/swift",
      exclude: [
        "objc"
      ])
  ]
)

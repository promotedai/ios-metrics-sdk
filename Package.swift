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
    .package(name: "PromotedAICommonSchema", path: "../../common-schema"),
    .package(name: "PromotedAISchema", path: "../../schema"),
    .package(name: "Protobuf", path: "../../protobuf"),
    .package(name: "SwiftProtobuf", url: "https://github.com/apple/swift-protobuf", from: "1.15.0"),
  ],
  targets: [
    .target(
      name: "PromotedAIMetricsSDK",
      dependencies: [
        .product(name: "CommonSchemaObjC", package: "PromotedAICommonSchema"),
        .product(name: "CommonSchemaSwift", package: "PromotedAICommonSchema"),
        .product(name: "GTMSessionFetcherCore", package: "GTMSessionFetcher"),
        .product(name: "Protobuf", package: "Protobuf"),
        .product(name: "SchemaObjC", package: "PromotedAISchema"),
        .product(name: "SchemaSwift", package: "PromotedAISchema"),
        .product(name: "SwiftProtobuf", package: "SwiftProtobuf"),
      ],
      cSettings: [
        .define("USE_SWIFT_PACKAGE_PROTOBUF_IMPORT"),
      ]),
    .testTarget(
      name: "PromotedAIMetricsSDKTests",
      dependencies: [
        "PromotedAIMetricsSDK"
      ],
      cSettings: [
        .define("USE_SWIFT_PACKAGE_PROTOBUF_IMPORT"),
      ]),
  ]
)

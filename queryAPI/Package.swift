// swift-tools-version:5.9

import PackageDescription

let package = Package(
  name: "QueryAPI",
  platforms: [
    .iOS(.v12),
    .macOS(.v10_14),
    .tvOS(.v12),
    .watchOS(.v5),
  ],
  products: [
    .library(name: "QueryAPI", targets: ["QueryAPI"]),
  ],
  dependencies: [
    .package(url: "https://github.com/apollographql/apollo-ios", exact: "1.16.0"),
  ],
  targets: [
    .target(
      name: "QueryAPI",
      dependencies: [
        .product(name: "ApolloAPI", package: "apollo-ios"),
      ],
      path: "./Sources"
    ),
  ]
)

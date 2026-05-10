// swift-tools-version: 5.9
import PackageDescription

let package = Package(
  name: "AgedCareShared",
  platforms: [.iOS(.v17), .macOS(.v14), .watchOS(.v10)],
  products: [
    .library(name: "AgedCareShared", targets: ["AgedCareShared"]),
  ],
  targets: [
    .target(name: "AgedCareShared"),
    .testTarget(name: "AgedCareSharedTests", dependencies: ["AgedCareShared"]),
  ]
)

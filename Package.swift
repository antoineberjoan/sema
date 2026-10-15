// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Sema",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "SemaMac", targets: ["SemaMac"]),
        .library(name: "MarketCore", targets: ["MarketCore"])
    ],
    targets: [
        .target(name: "MarketCore"),
        .executableTarget(name: "SemaMac", dependencies: ["MarketCore"]),
        .testTarget(name: "MarketCoreTests", dependencies: ["MarketCore"])
    ]
)

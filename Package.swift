// swift-tools-version: 6.0
// Déclare les cibles du cœur, de l’app macOS et des tests, sans dépendance externe.
import PackageDescription

let package = Package(
    name: "Sema",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "SemaMac", targets: ["SemaMac"]),
        .library(name: "MarketCore", targets: ["MarketCore"])
    ],
    targets: [
        .target(name: "MarketCore", exclude: ["AGENTS.md"]),
        .executableTarget(name: "SemaMac", dependencies: ["MarketCore"], exclude: ["AGENTS.md"]),
        .testTarget(name: "MarketCoreTests", dependencies: ["MarketCore"])
    ]
)

// swift-tools-version: 6.0
// Déclare les cibles du cœur, du design, de l’app macOS et des tests, sans dépendance externe.
import PackageDescription

let package = Package(
    name: "Sema",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "SemaMac", targets: ["SemaMac"]),
        .library(name: "MarketCore", targets: ["MarketCore"]),
        .library(name: "SemaDesign", targets: ["SemaDesign"])
    ],
    targets: [
        .target(name: "MarketCore", exclude: ["AGENTS.md"]),
        .target(name: "SemaDesign"),
        .executableTarget(name: "SemaMac", dependencies: ["MarketCore", "SemaDesign"], exclude: ["AGENTS.md"]),
        .testTarget(name: "MarketCoreTests", dependencies: ["MarketCore"]),
        .testTarget(name: "SemaDesignTests", dependencies: ["SemaDesign"])
    ]
)

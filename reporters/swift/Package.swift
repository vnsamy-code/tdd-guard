// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "tdd-guard-swift",
    platforms: [.macOS(.v13), .iOS(.v16)],
    products: [
        .library(
            name: "TDDGuardXCTest",
            targets: ["TDDGuardXCTest"]
        ),
    ],
    targets: [
        .target(
            name: "TDDGuardXCTest",
            dependencies: []
        ),
        .testTarget(
            name: "TDDGuardXCTestTests",
            dependencies: ["TDDGuardXCTest"]
        ),
    ]
)

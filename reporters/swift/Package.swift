// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "TDDGuardSwift",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "tdd-guard-swift", targets: ["TDDGuardSwift"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.3.0"),
    ],
    targets: [
        .executableTarget(
            name: "TDDGuardSwift",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ],
            path: "Sources/TDDGuardSwift"
        ),
        .testTarget(
            name: "TDDGuardSwiftTests",
            dependencies: ["TDDGuardSwift"],
            path: "Tests/TDDGuardSwiftTests"
        ),
    ]
)

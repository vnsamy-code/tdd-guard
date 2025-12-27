// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Calculator",
    platforms: [.macOS(.v13)],
    products: [
        .library(name: "Calculator", targets: ["Calculator"]),
    ],
    dependencies: [
        .package(path: "./swift")
    ],
    targets: [
        .target(name: "Calculator"),
        .testTarget(
            name: "CalculatorTests",
            dependencies: [
                "Calculator",
                .product(name: "TDDGuardXCTest", package: "swift")
            ]
        ),
    ]
)

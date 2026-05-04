// swift-tools-version: 6.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "pbshow",
    platforms: [.macOS(.v10_15)],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-testing.git", exact: "6.2.4")
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .executableTarget(
            name: "pbshow"
        ),
        .testTarget(
            name: "pbshowTests",
            dependencies: [
                "pbshow",
                .product(name: "Testing", package: "swift-testing"),
            ]
        ),
    ],
    swiftLanguageModes: [.v6]
)

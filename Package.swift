// swift-tools-version:5.0

import PackageDescription

let package = Package(
    name: "BoltsSwift",
    platforms: [.macOS(.v10_10),
                .iOS(.v8),
                .tvOS(.v9),
                .watchOS(.v3)],
    products: [
        .library(
            name: "BoltsSwift",
            targets: ["BoltsSwift"])
    ],
    targets: [
        .target(
            name: "BoltsSwift",
            path: "Sources/BoltsSwift"),
        .testTarget(
            name: "BoltsSwiftTests",
            dependencies: ["BoltsSwift"],
            path: "Tests")
    ],
    swiftLanguageVersions: [.v4,
                            .v4_2,
                            .v5]
)

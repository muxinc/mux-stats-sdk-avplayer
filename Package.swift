// swift-tools-version:5.9

import PackageDescription

let package = Package(
    name: "MUXSDKStats",
    platforms: [
        .iOS(.v12),
        .tvOS(.v12),
        .visionOS(.v1),
    ],
    products: [
        .library(name: "MUXSDKStats", targets: ["MUXSDKStatsTargets"])
    ],
    dependencies: [
        .package(
            url: "https://github.com/muxinc/stats-sdk-objc.git",
            .upToNextMinor(from: "5.3.0")
        )
    ],
    targets: [
        .binaryTarget(
            name: "MUXSDKStats",
            path: "XCFramework/MUXSDKStats.xcframework"
        ),
        .target(
            name: "MUXSDKStatsTargets",
            dependencies: [
                .product(name: "MuxCore", package: "stats-sdk-objc"),
                .target(name: "MUXSDKStats")
            ],
            path: "SwiftPM"
        )
    ]
)

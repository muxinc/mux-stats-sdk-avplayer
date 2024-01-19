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
            name: "MuxCore",
            path: "../mux-stats-sdk-objc/stats-sdk-objc"
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
                "MuxCore",
                .target(name: "MUXSDKStats")
            ],
            path: "SwiftPM"
        )
    ]
)

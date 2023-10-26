// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "MUXSDKStats",
    platforms: [
        .iOS(.v11),
        .tvOS(.v11)
    ],
    products: [
        .library(name: "MUXSDKStats", targets: ["MUXSDKStatsTargets"])
    ],
    dependencies: [
        .package(
            name: "MuxCore",
            url: "https://github.com/muxinc/stats-sdk-objc.git",
            .exactItem("4.6.0")
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

// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "MUXSDKStats",
    platforms: [
        .iOS(.v9),
        .tvOS(.v9)
    ],
    products: [
        .library(name: "MUXSDKStats", targets: ["MUXSDKStatsTargets"])
    ],
    dependencies: [
        .package(
            name: "MuxCore",
            url: "https://github.com/AndrewBarba/stats-sdk-objc.git",
            .branch("master")
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

// swift-tools-version:5.8

import PackageDescription

let package = Package(
    name: "MUXSDKStats",
    platforms: [
        .iOS(.v12),
        .macCatalyst(.v13),
        .tvOS(.v12),
    ],
    products: [
        .library(name: "MUXSDKStats", targets: ["MUXSDKStats"]),
    ],
    dependencies: [
        .package(
            url: "https://github.com/muxinc/stats-sdk-objc.git",
            .upToNextMinor(from: "5.4.0")),
    ],
    targets: [
        .target(
            name: "MUXSDKStats",
            dependencies: [
                .product(name: "MuxCore", package: "stats-sdk-objc"),
                .target(name: "MUXSDKStatsInternal"),
            ],
            resources: [
                .process("Resources"),
            ]),
        .target(
            name: "MUXSDKStatsInternal"),
        .testTarget(
            name: "MUXSDKStatsTests",
            dependencies: [
                "MUXSDKStats",
            ],
            cSettings: [
                .headerSearchPath("../../Sources/MUXSDKStats"),
            ]),
    ])

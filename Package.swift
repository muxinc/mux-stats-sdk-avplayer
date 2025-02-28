// swift-tools-version:5.9

import PackageDescription

let package = Package(
    name: "MUXSDKStats",
    platforms: [
        .iOS(.v12),
        .macCatalyst(.v13),
        .tvOS(.v12),
        .visionOS(.v1),
    ],
    products: [
        .library(name: "MUXSDKStats", targets: ["MUXSDKStats"]),
    ],
    dependencies: [
        .package(
            url: "https://github.com/muxinc/stats-sdk-objc.git",
            .upToNextMinor(from: "5.3.0")),
    ],
    targets: [
        .target(
            name: "MUXSDKStats",
            dependencies: [
                .product(name: "MuxCore", package: "stats-sdk-objc"),
            ],
            resources: [
                .process("Resources"),
            ]),
        .testTarget(
            name: "MUXSDKStatsTests",
            dependencies: [
                "MUXSDKStats",
            ],
            cSettings: [
                .headerSearchPath("../../Sources/MUXSDKStats"),
            ]),
    ]
)

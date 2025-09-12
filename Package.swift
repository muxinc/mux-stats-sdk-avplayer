// swift-tools-version:6.0

import PackageDescription

let package = Package(
    name: "MUXSDKStats",
    products: [
        .library(name: "MUXSDKStats", targets: ["MUXSDKStats"]),
    ],
    dependencies: [
        .package(
            url: "https://github.com/muxinc/stats-sdk-objc.git",
            from: "5.5.0"),
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
            name: "MUXSDKStatsInternal",
            dependencies: [
                .product(name: "MuxCore", package: "stats-sdk-objc"),
            ]),
        .testTarget(
            name: "MUXSDKStatsTests",
            dependencies: [
                "MUXSDKStats",
            ],
            cSettings: [
                .headerSearchPath("../../Sources/MUXSDKStats"),
            ]),
        .testTarget(
            name: "MUXSDKStatsInternalTests",
            dependencies: [
                "MUXSDKStatsInternal",
            ]),
        .plugin(
            name: "GeneratePodspec",
            capability: .command(
                intent: .custom(
                    verb: "generate-podspec",
                    description: "Generates a podspec for the SDK"))),
    ],
    swiftLanguageModes: [
        .v6,
    ]
)


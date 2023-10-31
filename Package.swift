// swift-tools-version:5.7

import PackageDescription

let package = Package(
    name: "MUXSDKStats",
    platforms: [
        .iOS(.v12),
        .tvOS(.v12)
    ],
    products: [
        .library(
            name: "MUXSDKStats", 
            targets: ["MUXSDKStatsObjc"]
        )
    ],
    dependencies: [
        .package(
            url: "https://github.com/muxinc/stats-sdk-objc.git", 
            exact: "4.6.0"
        )
    ],
    targets: [
        .target(
            name: "MUXSDKStatsObjc",
            dependencies: [
                .product(
                    name: "MuxCore",
                    package: "stats-sdk-objc"
                )
            ],
            publicHeadersPath: "include"
        ),
        .testTarget(
            name: "MUXSDKStatsObjcTests",
            dependencies: [
                "MUXSDKStatsObjc",
                .product(
                    name: "MuxCore",
                    package: "stats-sdk-objc"
                )
            ]
        )
    ]
)

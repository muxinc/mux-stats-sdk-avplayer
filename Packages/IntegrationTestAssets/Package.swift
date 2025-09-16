// swift-tools-version:5.5

import PackageDescription

let package = Package(
    name: "IntegrationTestAssets",
    platforms: [
        .iOS(.v12),
        .macCatalyst(.v13),
        .tvOS(.v12)
    ],
    products: [
        .library(
            name: "IntegrationTestAssets",
            targets: ["IntegrationTestAssets"]
        ),
    ],
    targets: [
        .target(
            name: "IntegrationTestAssets",
            resources: [
                .copy("assets")
            ]
        ),
    ]
)

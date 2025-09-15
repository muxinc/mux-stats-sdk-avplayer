// swift-tools-version:5.5

import PackageDescription

let package = Package(
    name: "IntegrationTestUtilities",
    platforms: [
        .iOS(.v12),
        .macCatalyst(.v13),
        .tvOS(.v12)
    ],
    products: [
        .library(
            name: "IntegrationTestUtilities",
            targets: ["IntegrationTestUtilities"]
        ),
    ],
    dependencies: [
        .package(path: "../IntegrationTestAssets"),
        .package(url: "https://github.com/httpswift/swifter.git", from: "1.5.0"),
    ],
    targets: [
        .target(
            name: "IntegrationTestUtilities",
            dependencies: [
                "IntegrationTestAssets",
                .product(name: "Swifter", package: "swifter"),
            ]
        ),
    ]
)

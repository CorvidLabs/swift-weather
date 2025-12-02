// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "weather-nft-example",
    platforms: [
        .macOS(.v14)
    ],
    dependencies: [
        .package(path: "../.."),  // swift-weather
        .package(path: "../../../swift-mint"),
        .package(path: "../../../swift-pinata"),
        .package(path: "../../../swift-ascii")
    ],
    targets: [
        .target(
            name: "SVG",
            dependencies: [
                .product(name: "Weather", package: "swift-weather"),
                .product(name: "ASCIIPixelArt", package: "swift-ascii")
            ],
            resources: [
                .copy("Resources/Icons")
            ]
        ),
        .executableTarget(
            name: "weather-nft-example",
            dependencies: [
                "SVG",
                .product(name: "Weather", package: "swift-weather"),
                .product(name: "Mint", package: "swift-mint"),
                .product(name: "Pinata", package: "swift-pinata"),
                .product(name: "ASCIIPixelArt", package: "swift-ascii")
            ]
        ),
        .testTarget(
            name: "SVGTests",
            dependencies: [
                "SVG",
                .product(name: "Weather", package: "swift-weather"),
                .product(name: "ASCIIPixelArt", package: "swift-ascii")
            ]
        )
    ]
)

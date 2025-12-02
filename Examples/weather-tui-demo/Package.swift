// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "weather-tui-demo",
    platforms: [.macOS(.v14)],
    dependencies: [
        .package(path: "../../../swift-cli"),
        .package(path: "../.."),  // swift-weather
        .package(path: "../../../swift-ascii")
    ],
    targets: [
        .executableTarget(
            name: "weather-tui-demo",
            dependencies: [
                .product(name: "CLI", package: "swift-cli"),
                .product(name: "Weather", package: "swift-weather"),
                .product(name: "ASCIIPixelArt", package: "swift-ascii")
            ]
        )
    ]
)

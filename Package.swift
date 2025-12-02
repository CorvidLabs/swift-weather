// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "swift-weather",
    platforms: [
        .iOS(.v16),
        .macOS(.v13),
        .tvOS(.v16),
        .watchOS(.v9),
        .visionOS(.v1)
    ],
    products: [
        .library(
            name: "Weather",
            targets: ["Weather"]
        )
    ],
    dependencies: [
        .package(
            url: "https://github.com/swiftlang/swift-docc-plugin",
            from: "1.4.3"
        )
    ],
    targets: [
        .target(name: "Weather"),
        .testTarget(
            name: "WeatherTests",
            dependencies: ["Weather"]
        )
    ]
)

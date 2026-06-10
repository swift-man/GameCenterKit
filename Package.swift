// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "GameCenterKit",
    platforms: [
        .iOS(.v15),
        .macOS(.v12),
        .tvOS(.v15),
        .visionOS(.v1),
    ],
    products: [
        .library(
            name: "GameCenterKit",
            targets: ["GameCenterKit"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/pointfreeco/swift-dependencies", from: "1.0.0"),
    ],
    targets: [
        .target(
            name: "GameCenterKit",
            dependencies: [
                .product(name: "Dependencies", package: "swift-dependencies"),
            ]
        ),
        .testTarget(
            name: "GameCenterKitTests",
            dependencies: [
                "GameCenterKit",
                .product(name: "Dependencies", package: "swift-dependencies"),
            ]
        ),
    ]
)

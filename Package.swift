// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "GameCenterKit",
    platforms: [
        .iOS(.v15),
        .macOS(.v12),
        .visionOS(.v1),
    ],
    products: [
        .library(
            name: "GameCenterKit",
            targets: ["GameCenterKit"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/swift-man/MaterialDesignColor.git", from: "2.1.0"),
        .package(url: "https://github.com/swift-man/ShimmerUI.git", from: "1.0.0"),
        .package(url: "https://github.com/pointfreeco/swift-dependencies", from: "1.0.0"),
    ],
    targets: [
        .target(
            name: "GameCenterKit",
            dependencies: [
                .product(name: "Dependencies", package: "swift-dependencies"),
                .product(name: "MaterialDesignColorSwiftUI", package: "MaterialDesignColor"),
                .product(name: "ShimmerUI", package: "ShimmerUI"),
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

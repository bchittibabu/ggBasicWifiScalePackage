// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ggWifiScalePackage",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "gWifiScalePackage",
            targets: ["ggWifiScalePackage"]),
    ],
    targets: [
        // Use dynamic linking for frameworks to allow proper system API access
        .binaryTarget(
            name: "ggEsptouchFramework",
            path: "Sources/ggWifiScalePackage/Vendor/ggEsptouchFramework.xcframework"
        ),
        .binaryTarget(
            name: "smartConfig",
            path: "Sources/ggWifiScalePackage/Vendor/smartConfig.xcframework"
        ),
        .target(
            name: "ggWifiScalePackage",
            dependencies: [
                "ggEsptouchFramework",
                "smartConfig"
            ],
            path: "Sources/ggWifiScalePackage",
            exclude: ["Vendor"]
        ),
    ]
)

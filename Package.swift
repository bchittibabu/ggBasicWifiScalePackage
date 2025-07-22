// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ggBasicWifiScalePackage",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "ggBasicWifiScalePackage",
            targets: ["ggBasicWifiScalePackage"]),
    ],
    targets: [
        // Use dynamic linking for frameworks to allow proper system API access
        .binaryTarget(
            name: "ggEsptouchFramework",
            path: "Sources/ggBasicWifiScalePackage/Vendor/ggEsptouchFramework.xcframework"
        ),
        .binaryTarget(
            name: "smartConfig",
            path: "Sources/ggBasicWifiScalePackage/Vendor/smartConfig.xcframework"
        ),
        .target(
            name: "ggBasicWifiScalePackage",
            dependencies: [
                "ggEsptouchFramework",
                "smartConfig"
            ],
            path: "Sources/ggBasicWifiScalePackage",
            exclude: ["Vendor"],
            linkerSettings: [
                .linkedFramework("SystemConfiguration"),
                .linkedFramework("CoreLocation"),
                .linkedFramework("Network"),
                .linkedFramework("Foundation"),
                .linkedFramework("CFNetwork"),
                .linkedLibrary("resolv"),
                .linkedLibrary("z"),
                .unsafeFlags(["-ObjC", "-all_load"]) // Required for proper Objective-C runtime linking and dynamic loading
            ]
        ),
        .testTarget(
            name: "ggBasicWifiScalePackageTests",
            dependencies: ["ggBasicWifiScalePackage"]
        ),
    ]
)

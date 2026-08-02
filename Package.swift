// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "WellnessBuddy",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "WellnessBuddy",
            targets: ["WellnessBuddy"]
        ),
    ],
    targets: [
        .target(
            name: "WellnessBuddy",
            path: "WellnessBuddy",
            exclude: ["Info.plist", "Assets.xcassets"]
        )
    ]
)

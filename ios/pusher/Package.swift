// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "pusher",
    platforms: [
        .iOS("15.0")
    ],
    products: [
        // Flutter host (MethodChannel plugin).
        .library(name: "pusher", targets: ["pusher"]),
        // NSE / native-only (no Flutter.framework).
        .library(name: "pusher-core", targets: ["pusher_core"]),
    ],
    dependencies: [
        .package(name: "FlutterFramework", path: "../FlutterFramework")
    ],
    targets: [
        .target(
            name: "pusher_core",
            path: "Sources/pusher",
            exclude: [
                "PusherPlugin.swift",
                "PrivacyInfo.xcprivacy",
            ]
        ),
        .target(
            name: "pusher",
            dependencies: [
                "pusher_core",
                .product(name: "FlutterFramework", package: "FlutterFramework")
            ],
            path: "Sources/pusher",
            sources: [
                "PusherPlugin.swift",
            ]
        )
    ]
)

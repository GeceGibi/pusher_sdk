// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "PusherStats",
    platforms: [
        .iOS("15.0")
    ],
    products: [
        .library(name: "PusherStats", targets: ["PusherStats"]),
    ],
    targets: [
        .target(
            name: "PusherStats",
            path: "Sources/PusherStats",
            resources: [
                .copy("PrivacyInfo.xcprivacy")
            ]
        )
    ]
)

// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "CloudInAppMessaging",
    platforms: [
        .iOS(.v10),
    ],
    products: [
        .library(
            name: "CloudInAppMessaging",
            targets: ["CloudInAppMessaging"]
        ),
    ],
    targets: [
        .target(
            name: "CloudInAppMessaging"
        ),
    ]
)

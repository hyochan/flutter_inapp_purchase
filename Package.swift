// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "flutter_inapp_purchase",
    platforms: [
        .iOS("12.0")
    ],
    products: [
        .library(name: "flutter-inapp-purchase", targets: ["flutter_inapp_purchase"])
    ],
    dependencies: [],
    targets: [
        .target(
            name: "flutter_inapp_purchase",
            dependencies: [],
            path: "ios/Classes",
            resources: [
                .process("../Assets")
            ],
            publicHeadersPath: "",
            cSettings: [
                .headerSearchPath("../Flutter"),
                .headerSearchPath("../../../Flutter/Export")
            ]
        )
    ]
)
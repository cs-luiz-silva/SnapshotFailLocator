// swift-tools-version:4.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SnapshotFailLocator",
    dependencies: [
        .package(url: "https://github.com/LuizZak/console.git",
                 from: "0.4.2")
    ],
    targets: [
        .target(
            name: "SnapshotFailLocator",
            dependencies: ["Console"]),
    ]
)

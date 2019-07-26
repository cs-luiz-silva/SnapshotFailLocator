// swift-tools-version:5.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SnapshotFailLocator",
    dependencies: [
        .package(url: "https://github.com/LuizZak/console.git",
                 from: "0.8.0")
    ],
    targets: [
        .target(
            name: "SnapshotFailLocatorLib",
            dependencies: []),
        .target(
            name: "SnapshotFailLocator",
            dependencies: ["SnapshotFailLocatorLib", "Console"]),
        .testTarget(
            name: "SnapshotFailLocatorLibTests",
            dependencies: ["SnapshotFailLocatorLib"]),
    ]
)

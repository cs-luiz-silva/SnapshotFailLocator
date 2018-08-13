// swift-tools-version:4.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SnapshotFailLocator",
    dependencies: [
        .package(url: "https://bitbucket.org/cs-luiz-silva/console.git", from: "0.3.0")
    ],
    targets: [
        .target(
            name: "SnapshotFailLocator",
            dependencies: ["Console"]),
    ]
)

// swift-tools-version:5.1

import PackageDescription

let package = Package(
    name: "SwiftArkku",
    platforms: [
        .macOS(.v10_13),
        .iOS(.v11),
    ],
    products: [
        .library(
            name: "SwiftArkku",
            targets: ["Data Structures", "Extensions", "Formats", "Wrappers"]),
    ],
    targets: [
        .target(
            name: "Data Structures",
            dependencies: []),
        .target(
            name: "Extensions",
            dependencies: []),
        .target(
            name: "Formats",
            dependencies: []),
        .target(
            name: "Wrappers",
            dependencies: ["Formats"]),
    ]
)

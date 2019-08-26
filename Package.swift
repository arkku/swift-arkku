// swift-tools-version:5.1

import PackageDescription

let package = Package(
    name: "SwiftArkku",
    platforms: [
        .macOS(.v10_13),
        .iOS(.v11),
    ],
    products: [
        .library(name: "SwiftArkku", targets: ["SwiftArkku"]),
    ],
    targets: [
        .target(name: "SwiftArkku", dependencies: []),
    ]
)

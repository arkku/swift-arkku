// swift-tools-version:4.0

import PackageDescription

let package = Package(
    name: "swift-arkku",
    products: [
        .library(name: "SwiftArkku", targets: [
            "SwiftArkkuWrappers",
            "SwiftArkkuFormats"
        ]),
    ],
    targets: [
        .target(name: "SwiftArkkuWrappers", dependencies: [], path: "Wrappers"),
        .target(name: "SwiftArkkuFormats", dependencies: [], path: "Formats"),
    ]
)

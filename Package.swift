// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "CSFileReference",
    platforms: [
        .macOS(.v10_15),
        .macCatalyst(.v13),
        .iOS(.v13),
        .tvOS(.v13),
        .watchOS(.v6),
        .visionOS(.v1)
    ],
    products: [
        .library(
            name: "FileReference",
            targets: ["FileReference"]
        ),
        .library(
            name: "HTTPFileReference",
            targets: ["HTTPFileReference"]
        ),
        .library(
            name: "RawPOSIXFileReference",
            targets: ["RawPOSIXFileReference"]
        ),
        .library(
            name: "SystemFileReference",
            targets: ["SystemFileReference"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-async-algorithms", from: "1.0.2"),
        .package(url: "https://github.com/CharlesJS/CSErrors", from: "1.2.9"),
        .package(url: "https://github.com/CharlesJS/SyncPolyfill", from: "0.1.0"),
    ],
    targets: [
        .target(
            name: "FileReference"
        ),
        .target(
            name: "HTTPFileReference",
            dependencies: [
                "FileReference"
            ]
        ),
        .target(
            name: "RawPOSIXFileReference",
            dependencies: [
                "CSErrors",
                "FileReference",
                "SyncPolyfill",
            ]
        ),
        .target(
            name: "SystemFileReference",
            dependencies: [
                .product(name: "AsyncAlgorithms", package: "swift-async-algorithms"),
                "FileReference",
                "SyncPolyfill",
            ]
        ),
        .testTarget(
            name: "FileReferenceTests",
            dependencies: [
                "FileReference",
                "HTTPFileReference",
                "RawPOSIXFileReference",
                "SystemFileReference",
                "SyncPolyfill"
            ],
            resources: [
                .copy("Fixtures"),
            ]
        ),
    ]
)

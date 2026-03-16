// swift-tools-version: 6.1

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
        // NOTE: HTTPFileReference is only available when the Foundation trait is enabled
        .library(
            name: "HTTPFileReference",
            targets: ["HTTPFileReference"],
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
    traits: [
        "Foundation"
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-async-algorithms", from: "1.1.3"),
        .package(
            url: "https://github.com/CharlesJS/CSErrors", 
            from: "2.0.0",
            traits: [.trait(name: "Foundation", condition: .when(traits: ["Foundation"]))]
        ),
        .package(url: "https://github.com/CharlesJS/SyncPolyfill", from: "0.1.1"),
    ],
    targets: [
        .target(
            name: "FileReference",
            dependencies: []
        ),
        .target(
            name: "HTTPFileReference",
            dependencies: [
                "FileReference"
            ],
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

// swift-tools-version: 6.3

import CompilerPluginSupport
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
    ],
    traits: [
        "Foundation",
        "Macros",
        .trait(name: "Networking", enabledTraits: ["Foundation"]),
        .default(enabledTraits: ["Networking", "Macros"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-system", from: "1.6.1"),
        .package(
            url: "https://github.com/CharlesJS/CSErrors", 
            from: "2.1.1",
            traits: [.trait(name: "Foundation", condition: .when(traits: ["Foundation"]))]
        ),
        .package(url: "https://github.com/CharlesJS/SyncPolyfill", from: "0.2.1"),
        .package(url: "https://github.com/swiftlang/swift-syntax", "604.0.0"..<"900.0.0"),
    ],
    targets: [
        .target(
            name: "FileReference",
            dependencies: [
                "CSErrors",
                "SyncPolyfill",
                .product(name: "SystemPackage", package: "swift-system", condition: .when(platforms: [.linux])),
                .target(name: "FileReferenceMacros", condition: .when(traits: ["Macros"]))
            ]
        ),
        .testTarget(
            name: "FileReferenceTests",
            dependencies: [
                .product(name: "SystemPackage", package: "swift-system", condition: .when(platforms: [.linux])),
                "FileReference",
                "SyncPolyfill"
            ],
            resources: [
                .copy("Fixtures"),
            ]
        ),
        .macro(
            name: "FileReferenceMacros",
            dependencies: [
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax", condition: .when(traits: ["Macros"])),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax", condition: .when(traits: ["Macros"])),
            ]
        ),
        .testTarget(
            name: "FileReferenceMacrosTests",
            dependencies: [
                .target(name: "FileReferenceMacros", condition: .when(traits: ["Macros"])),
                .product(name: "SwiftSyntaxMacrosTestSupport", package: "swift-syntax", condition: .when(traits: ["Macros"]))
            ]
        ),
    ]
)

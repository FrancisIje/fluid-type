// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "FluidType",
    platforms: [
        .iOS(.v15),
        .macOS(.v12),
        .tvOS(.v15),
        .watchOS(.v8),
    ],
    products: [
        .library(name: "FluidType", targets: ["FluidType"])
    ],
    targets: [
        .target(
            name: "FluidType",
            swiftSettings: [.enableExperimentalFeature("StrictConcurrency")]
        ),
        // The specimen is a plain target rather than a product: it is not
        // something consumers should link, but building it on every `swift
        // build` means the example in the README cannot rot unnoticed.
        .target(name: "FluidTypeSpecimen", dependencies: ["FluidType"], path: "Example"),
        .testTarget(name: "FluidTypeTests", dependencies: ["FluidType"]),
    ]
)

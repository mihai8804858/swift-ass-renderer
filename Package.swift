// swift-tools-version:5.9
import PackageDescription
import Foundation

let package = Package(
    name: "swift-ass-renderer",
    platforms: [
        .iOS(.v16),
        .tvOS(.v16),
        .visionOS(.v1),
        .macOS(.v13),
        .macCatalyst(.v16)
    ],
    products: [
        .library(name: "SwiftAssRenderer", targets: ["SwiftAssRenderer"])
    ],
    dependencies: [
        .package(url: "https://github.com/mihai8804858/swift-libass", branch: "main"),
        .package(url: "https://github.com/pointfreeco/combine-schedulers", .upToNextMajor(from: "1.0.0")),
        .package(url: "https://github.com/mihai8804858/swift-snapshot-testing", branch: "visionos-support")
    ],
    targets: [
        .target(
            name: "SwiftAssRenderer",
            dependencies: [
                .product(name: "SwiftLibass", package: "swift-libass"),
                .product(name: "CombineSchedulers", package: "combine-schedulers")
            ],
            path: "Sources",
            resources: [
                .copy("Resources/PrivacyInfo.xcprivacy"),
                .copy("Resources/fonts.conf")
            ]
        ),
        .testTarget(
            name: "SwiftAssRendererTests",
            dependencies: [
                .target(name: "SwiftAssRenderer"),
                .product(name: "SnapshotTesting", package: "swift-snapshot-testing")
            ],
            path: "Tests",
            resources: [
                .copy("Resources/Fonts.bundle"),
                .copy("Resources/subtitle.ass")
            ]
        )
    ]
)

// swift-tools-version:5.10
import PackageDescription
import Foundation

let package = Package(
    name: "swift-ass-renderer",
    platforms: [
        .iOS(.v15),
        .tvOS(.v15),
        .visionOS(.v1),
        .macOS(.v12),
        .macCatalyst(.v15)
    ],
    products: [
        .library(name: "SwiftAssRenderer", targets: ["SwiftAssRenderer"])
    ],
    dependencies: [
        .package(url: "https://github.com/mihai8804858/swift-snapshot-testing", branch: "main"),
        .package(url: "https://github.com/mihai8804858/swift-libass", .upToNextMajor(from: "1.0.0")),
        .package(url: "https://github.com/pointfreeco/combine-schedulers", .upToNextMajor(from: "1.0.0"))
    ],
    targets: [
        .target(
            name: "SwiftAssRenderer",
            dependencies: [
                .target(name: "SwiftAssBlend"),
                .product(name: "SwiftLibass", package: "swift-libass"),
                .product(name: "CombineSchedulers", package: "combine-schedulers")
            ],
            path: "Sources/SwiftAssRenderer",
            resources: [
                .copy("Resources/PrivacyInfo.xcprivacy")
            ]
        ),
        .target(
            name: "SwiftAssBlend",
            dependencies: [
                .product(name: "SwiftLibass", package: "swift-libass")
            ],
            path: "Sources/SwiftAssBlend"
        ),
        .testTarget(
            name: "SwiftAssRendererTests",
            dependencies: [
                .target(name: "SwiftAssRenderer"),
                .product(name: "SnapshotTesting", package: "swift-snapshot-testing")
            ],
            path: "Tests",
            exclude: ["Pipeline/__Snapshots__"],
            resources: [
                .copy("Resources/Fonts"),
                .copy("Resources/Subs")
            ]
        )
    ],
    swiftLanguageVersions: [.v5]
)

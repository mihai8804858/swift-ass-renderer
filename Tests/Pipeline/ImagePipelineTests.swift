import XCTest
import SwiftUI
import SwiftLibass
import SnapshotTesting
@testable import SwiftAssRenderer

#if os(iOS) || os(tvOS) || os(visionOS)
final class ImagePipelineTests: XCTestCase {
    private var library: OpaquePointer!
    private var renderer: OpaquePointer!
    private var track: ASS_Track!
    private let canvasSize = CGSize(width: 640, height: 360)
    private let canvasScale = 3.0
    private let pipeline = ImagePipeline()
    private let offsets: [TimeInterval] = [
        40.0,
        72.72,
        374.52,
        389.79,
        392.08,
        406.84,
        409.43,
        813.64,
        832.70,
        837.94,
        862.48,
        1354.62
    ]

    override func setUp() async throws {
        try await super.setUp()

        library = try XCTUnwrap(LibraryWrapper.libraryInit())
        renderer = try XCTUnwrap(LibraryWrapper.rendererInit(library))
        LibraryWrapper.setRendererSize(renderer, size: canvasSize * canvasScale)

        let fontsPath = try XCTUnwrap(Bundle.module.path(forResource: "Fonts", ofType: "bundle"))
        let fontConfig = FontConfig(fontsPath: URL(fileURLWithPath: fontsPath))
        try fontConfig.configure(library: library, renderer: renderer)

        let contentsPath = try XCTUnwrap(Bundle.module.path(forResource: "subtitle", ofType: "ass"))
        let content = try String(contentsOfFile: contentsPath)
        track = try XCTUnwrap(LibraryWrapper.readTrack(library, content: content))
    }

    func test_processImage() throws {
        for offset in offsets {
            guard let image = LibraryWrapper.renderImage(renderer, track: &track, at: offset) else { continue }
            guard let processedImage = pipeline.process(image: image.image) else { continue }
            assertSnapshot(of: value(image: processedImage), as: .image, named: snapshotName(offset: offset))
        }
    }

    private func snapshotName(offset: TimeInterval) -> String {
        "\(platformName())_\(String(offset).split(separator: ".").joined(separator: "_"))"
    }

    private func platformName() -> String {
        #if targetEnvironment(macCatalyst)
        "maccatalyst"
        #elseif os(iOS)
        "ios"
        #elseif os(tvOS)
        "tvos"
        #elseif os(macOS)
        "macos"
        #elseif os(visionOS)
        "visionos"
        #endif
    }

    private func value(image: ProcessedImage) -> CALayer {
        let layer = CALayer()
        layer.bounds = CGRect(origin: .zero, size: image.imageRect.size)
        layer.contents = image.image
        layer.contentsGravity = .center

        return layer
    }
}
#endif

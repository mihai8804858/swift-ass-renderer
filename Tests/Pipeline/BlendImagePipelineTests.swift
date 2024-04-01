import XCTest
import SwiftUI
import SwiftLibass
import SnapshotTesting
@testable import SwiftAssRenderer

final class BlendImagePipelineTests: XCTestCase {
    private var library: OpaquePointer!
    private var renderer: OpaquePointer!
    private var track: ASS_Track!
    private let canvasSize = CGSize(width: 640, height: 360)
    private let canvasScale = 3.0
    private let pipeline = BlendImagePipeline()
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

    func test_processImage() throws {
        for subtitle in ["en", "ru", "ar"] {
            try setup(fontProvider: .fontConfig, subtitle: subtitle)
            for offset in offsets {
                let image = try XCTUnwrap(LibraryWrapper.renderImage(renderer, track: &track, at: offset))
                let processedImage = try XCTUnwrap(pipeline.process(image: image.image))
                assertSnapshot(
                    of: value(image: processedImage),
                    as: .image,
                    named: snapshotName(offset: offset),
                    snapshotDirectory: snapshotsDirectory(pathComponents: platformName(), subtitle)
                )
            }
        }
    }

    func test_processImage_fontConfig_shouldNotCrash() throws {
        measure {
            do {
                for subtitle in ["en", "ru", "ar"] {
                    try setup(fontProvider: .fontConfig, subtitle: subtitle)
                    for event in Array(UnsafeBufferPointer(start: track.events, count: Int(track.n_events))) {
                        let offset = TimeInterval(event.Start) / 1000
                        guard let image = LibraryWrapper.renderImage(renderer, track: &track, at: offset) else {
                            continue
                        }
                        _ = pipeline.process(image: image.image)
                    }
                }
            } catch {
                XCTFail(error.localizedDescription)
            }
        }
    }

    func test_processImage_coreText_shouldNotCrash() throws {
        measure {
            do {
                for subtitle in ["en", "ru", "ar"] {
                    try setup(fontProvider: .coreText, subtitle: subtitle)
                    for event in Array(UnsafeBufferPointer(start: track.events, count: Int(track.n_events))) {
                        let offset = TimeInterval(event.Start) / 1000
                        guard let image = LibraryWrapper.renderImage(renderer, track: &track, at: offset) else {
                            continue
                        }
                        _ = pipeline.process(image: image.image)
                    }
                }
            } catch {
                XCTFail(error.localizedDescription)
            }
        }
    }

    private func snapshotName(offset: TimeInterval) -> String {
        "\(String(offset).split(separator: ".").joined(separator: "_"))"
    }

    private func value(image: ProcessedImage) -> CALayer {
        let layer = CALayer()
        layer.bounds = CGRect(origin: .zero, size: image.imageRect.size)
        layer.contents = image.image
        layer.contentsGravity = .center

        return layer
    }

    private func setup(fontProvider: FontProvider, subtitle: String) throws {
        library = try XCTUnwrap(LibraryWrapper.libraryInit())
        renderer = try XCTUnwrap(LibraryWrapper.rendererInit(library))
        LibraryWrapper.setRendererSize(renderer, size: canvasSize * canvasScale)
        let fontsPath = try XCTUnwrap(Bundle.module.resourceURL)
        let fontConfig = FontConfig(fontsPath: fontsPath.appendingPathComponent("Fonts"), fontProvider: fontProvider)
        try fontConfig.configure(library: library, renderer: renderer)
        let contentsPath = try XCTUnwrap(Bundle.module.resourceURL?.appendingPathComponent("Subs/\(subtitle).ass"))
        let content = try String(contentsOfFile: contentsPath.path)
        track = try XCTUnwrap(LibraryWrapper.readTrack(library, content: content))
    }
}

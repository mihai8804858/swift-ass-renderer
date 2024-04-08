import XCTest
import SwiftUI
import SwiftLibass
import SnapshotTesting
@testable import SwiftAssRenderer

open class PipelineTestCase: XCTestCase {
    let canvasSize = CGSize(width: 640, height: 360)
    let canvasScale = 3.0

    open var library: OpaquePointer!
    open var renderer: OpaquePointer!
    open var track: ASS_Track!

    func render(offset: TimeInterval, pipeline: ImagePipelineType) -> ProcessedImage? {
        guard let image = LibraryWrapper.renderImage(renderer, track: &track, at: offset) else { return nil }
        let images = linkedImages(from: image.image)
        let boundingRect = imagesBoundingRect(images: images)

        return pipeline.process(images: images, boundingRect: boundingRect)
    }

    func snapshotName(offset: TimeInterval) -> String {
        "\(String(offset).split(separator: ".").joined(separator: "_"))"
    }

    func value(image: ProcessedImage) -> CALayer {
        let layer = CALayer()
        layer.bounds = CGRect(origin: .zero, size: image.imageRect.size)
        layer.contents = image.image
        layer.contentsGravity = .center

        return layer
    }

    func setup(fontProvider: FontProvider, subtitle: String) throws {
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

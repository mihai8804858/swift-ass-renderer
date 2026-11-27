import Foundation
import Testing
import SwiftUI
import SwiftLibass
@testable import SwiftAssRenderer

/// A real libass library, renderer and track that pipeline tests render frames from.
struct PipelineHarness {
    let canvasSize = CGSize(width: 640, height: 360)
    let canvasScale = 3.0

    private(set) var library: OpaquePointer!
    private(set) var renderer: OpaquePointer!
    private(set) var track: ASS_Track!

    var events: [ASS_Event] {
        Array(UnsafeBufferPointer(start: track.events, count: Int(track.n_events)))
    }

    mutating func render(offset: TimeInterval, pipeline: ImagePipelineType) -> ProcessedImage? {
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

    mutating func setup(fontProvider: FontProvider, subtitle: String) throws {
        let library = try #require(LibraryWrapper.libraryInit())
        let renderer = try #require(LibraryWrapper.rendererInit(library))
        self.library = library
        self.renderer = renderer
        LibraryWrapper.setRendererSize(renderer, size: canvasSize * canvasScale)
        let fontsPath = try #require(Bundle.module.resourceURL)
        let fontConfig = FontConfig(fontsPath: fontsPath.appendingPathComponent("Fonts"), fontProvider: fontProvider)
        try fontConfig.configure(library: library, renderer: renderer)
        let contentsPath = try #require(Bundle.module.resourceURL?.appendingPathComponent("Subs/\(subtitle).ass"))
        let content = try String(contentsOfFile: contentsPath.path)
        let track = try #require(LibraryWrapper.readTrack(library, content: content))
        self.track = track
    }
}

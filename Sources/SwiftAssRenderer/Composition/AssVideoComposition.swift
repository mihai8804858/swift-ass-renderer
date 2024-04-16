#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif
import AVFoundation
import CoreImage

@available(iOS 16.0, tvOS 16.0, visionOS 1.0, macCatalyst 16.0, macOS 13.0, *)
final class AssVideoComposition {
    private let scale: CGFloat
    private let asset: AVAsset
    private let renderer: AssSubtitlesRenderer

    init(asset: AVAsset, renderer: AssSubtitlesRenderer, scale: CGFloat) {
        self.scale = scale
        self.asset = asset
        self.renderer = renderer
    }

    func makeAVVideoComposition() async throws -> AVVideoComposition {
        try await AVVideoComposition.videoComposition(with: asset) { request in
            self.process(request)
        }
    }

    private func process(_ request: AVAsynchronousCIImageFilteringRequest) {
        let sourceImage = request.sourceImage.clampedToExtent()
        renderer.setCanvasSize(request.renderSize, scale: scale)
        renderer.loadFrame(offset: request.compositionTime.seconds) { [weak self] subtitleImage in
            guard let self, let subtitleImage else { return request.finish(with: sourceImage, context: nil) }
            renderSubtitle(sourceImage: sourceImage, subtitleImage: subtitleImage, request: request)
        }
    }

    private func renderSubtitle(
        sourceImage: CIImage,
        subtitleImage: ProcessedImage,
        request: AVAsynchronousCIImageFilteringRequest
    ) {
        let subtitleTransform = CGAffineTransform.identity.translatedBy(
            x: subtitleImage.imageRect.minX,
            y: subtitleImage.imageRect.flippingY(for: request.renderSize.height).minY
        ).scaledBy(
            x: 1 / scale,
            y: 1 / scale
        )
        let subtitleOverlay = CIImage(cgImage: subtitleImage.image).transformed(by: subtitleTransform)
        let outputFrame = subtitleOverlay
            .composited(over: sourceImage)
            .cropped(to: request.sourceImage.extent)
        request.finish(with: outputFrame, context: nil)
    }
}

import SwiftUI
import AVKit
import SwiftLibass
import SwiftAssRenderer

struct VideoPlayerView: View {
    private let player = AVPlayer(url: ...)
    private let renderer = AssSubtitlesRenderer(
        fontConfig: FontConfig(fontsPath: ...),
        pipeline: ImagePipeline()
    )

    var body: some View {
        VideoPlayer(player: player) {
            AssSubtitles(renderer: renderer)
                .attach(player: player, updateInterval: CMTime(value: 1, timescale: 10))
        }
        .onAppear(perform: setupPlayer)
        .onAppear(perform: loadSubtitleTrack)
    }

    private func setupPlayer() {
        player.play()
    }

    private func loadSubtitleTrack() {
        Task {
            do {
                let contents = try await ...
                renderer.loadTrack(content: contents)
            } catch {
                print(error)
            }
        }
    }
}

final class ImagePipeline: ImagePipelineType {
    func process(images: [ASS_Image], boundingRect: CGRect) -> ProcessedImage? {
        let cgImages = images.compactMap(makeCGImage)
        let finalImage = combineCGImages(cgImages, boundingRect: boundingRect)

        return finalImage.flatMap { ProcessedImage(image: $0, imageRect: boundingRect) }
    }

    private func makeCGImage(from image: ASS_Image) -> (CGRect, CGImage)? {
        let origin = CGPoint(x: Int(image.dst_x), y: Int(image.dst_y))
        let size = CGSize(width: Int(image.w), height: Int(image.h))
        let rect = CGRect(origin: origin, size: size)
        guard let bitmap = palettizedBitmapRGBA(image),
              let buffer = bitmap.baseAddress,
              let cgImage = makeCGImage(
                buffer: buffer,
                size: size,
                colorSpace: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.last.rawValue)
              ) else { return nil }

        return (rect, cgImage)
    }

    private func combineCGImages(_ images: [(CGRect, CGImage)], boundingRect: CGRect) -> CGImage? {

    }
}

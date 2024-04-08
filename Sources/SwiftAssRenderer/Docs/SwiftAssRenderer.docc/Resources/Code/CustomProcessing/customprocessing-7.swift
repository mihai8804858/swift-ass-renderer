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
    }

    private func makeCGImage(from image: ASS_Image) -> (CGRect, CGImage)? {

    }
}

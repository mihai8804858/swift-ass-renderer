import SwiftUI
import AVKit
import SwiftAssRenderer

struct VideoPlayerView: View {
    let player = AVPlayer(url: ...)

    let renderer = AssSubtitlesRenderer(
        fontConfig: FontConfig(fontsPath: ...)
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

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
    }

    private func setupPlayer() {
        player.play()
    }
}

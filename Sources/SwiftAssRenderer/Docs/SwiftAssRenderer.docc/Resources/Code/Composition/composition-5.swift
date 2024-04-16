import SwiftUI
import AVKit
import SwiftAssRenderer

struct VideoPlayerView: View {
    let asset = AVURLAsset(url: ...)
    let playerItem = AVPlayerItem(asset: asset)
    let player = AVPlayer(playerItem: playerItem)

    let renderer = AssSubtitlesRenderer(
        fontConfig: FontConfig(fontsPath: ...)
    )

    var body: some View {
        VideoPlayer(player: player)
            .onAppear(perform: setupPlayer)
    }

    private func setupPlayer() {
        player.play()
    }
}

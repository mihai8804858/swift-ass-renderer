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
            .onAppear(perform: loadSubtitleTrack)
    }

    private func setupPlayer() {
        renderer.attach(to: playerItem, asset: asset)
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

import SwiftUI
import AVKit
import SwiftAssRenderer

struct VideoPlayerView: View {
    let asset = AVURLAsset(url: ...)
    let playerItem = AVPlayerItem(asset: asset)
    let player = AVPlayer(playerItem: playerItem)

    var body: some View {

    }
}

import SwiftUI
import AVKit
import SwiftLibass
import SwiftAssRenderer

struct VideoPlayerView: View {
    private let player = AVPlayer(url: ...)
    private let renderer = AssSubtitlesRenderer(
        fontConfig: FontConfig(fontsPath: ...)
    )

    var body: some View {

    }
}

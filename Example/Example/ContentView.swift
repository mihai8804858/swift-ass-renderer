import SwiftUI
import AVKit
import SwiftAssRenderer

struct ContentView: View {
    private let defaultFont = "arialuni.ttf"
    private let videoURL = Bundle.main.url(forResource: "video", withExtension: "mp4")!
    private let subtitleURL = Bundle.main.url(forResource: "subtitle", withExtension: "ass")!
    private let fontsURL = Bundle.main.url(forResource: "Fonts", withExtension: "bundle")!

    private let player: AVPlayer
    private let fontsConfig: FontConfig
    private let renderer: AssSubtitlesRenderer

    @State private var isPaused = false

    init() {
        player = AVPlayer(url: videoURL)
        fontsConfig = FontConfig(fontsPath: fontsURL, defaultFontName: defaultFont)
        renderer = AssSubtitlesRenderer(fontConfig: fontsConfig)
    }

    var body: some View {
        VideoPlayer(player: player) {
            AssSubtitles(renderer: renderer)
        }
        .aspectRatio(16 / 9, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerSize: CGSize(width: 8, height: 8)))
        .padding()
        .onAppear(perform: setupPlayer)
        .onAppear(perform: loadSubtitleTrack)
        .onReceive(player.publisher(for: \.timeControlStatus), perform: onControlStatusChanged)
    }

    private func setupPlayer() {
        player.play()
        player.addPeriodicTimeObserver(
            forInterval: CMTime(value: 1, timescale: 10),
            queue: .main,
            using: { renderer.setTimeOffset($0.seconds) }
        )
    }

    private func loadSubtitleTrack() {
        do {
            renderer.loadTrack(content: try String(contentsOf: subtitleURL))
        } catch {
            print(error)
        }
    }

    private func onControlStatusChanged(_ status: AVPlayer.TimeControlStatus) {
        isPaused = status == .paused
    }

    private func onCurrentTimeChanged(_ time: CMTime) {
        renderer.setTimeOffset(time.seconds)
    }
}

import SwiftUI
import AVKit
import SwiftAssRenderer

struct VideoPlayerView: View {
    private let defaultFont = "arialuni.ttf"
    private let videoURL = Bundle.main.url(forResource: "video", withExtension: "mp4")!
    private let fontsURL = Bundle.main.resourceURL!
    private let player: AVPlayer
    private let renderer: AssSubtitlesRenderer
    private let subtitleURL: URL
    private let fontProvider: FontProvider

    @Environment(\.presentationMode) private var presentationMode: Binding<PresentationMode>

    init(subtitleURL: URL, fontProvider: FontProvider) {
        self.subtitleURL = subtitleURL
        self.fontProvider = fontProvider
        self.player = AVPlayer(url: videoURL)
        self.renderer = AssSubtitlesRenderer(fontConfig: FontConfig(
            fontsPath: fontsURL,
            defaultFontName: defaultFont,
            fontProvider: fontProvider
        ), logLevel: .verbose)
    }

    var body: some View {
        playerView
            #if os(visionOS)
            .padding(48)
            #else
            .padding(8)
            #endif
            .onAppear(perform: setupPlayer)
            .onAppear(perform: loadSubtitleTrack)
            #if os(visionOS) || os(macOS)
            .overlay(alignment: .topLeading) {
                Button {
                    presentationMode.wrappedValue.dismiss()
                } label: {
                    Text("Back")
                }
                #if os(visionOS)
                .padding(72)
                #elseif os(macOS)
                .padding()
                #endif
            }
            .frame(width: 1920, height: 1080)
            .fixedSize()
            #endif
    }

    @ViewBuilder
    private var playerView: some View {
        VideoPlayer(player: player) {
            AssSubtitles(renderer: renderer)
        }
        .aspectRatio(16 / 9, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerSize: CGSize(width: 8, height: 8)))
    }

    private func setupPlayer() {
        player.play()
        player.addPeriodicTimeObserver(
            forInterval: CMTime(value: 1, timescale: 60),
            queue: .main,
            using: setTimeOffset
        )
    }

    private func loadSubtitleTrack() {
        do {
            renderer.loadTrack(content: try String(contentsOf: subtitleURL))
        } catch {
            print(error)
        }
    }

    private func setTimeOffset(_ offset: CMTime) {
        renderer.setTimeOffset(offset.seconds)
    }
}

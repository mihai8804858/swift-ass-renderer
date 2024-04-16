import SwiftUI
import AVKit
import SwiftAssRenderer

struct VideoPlayerView: View {
    private let defaultFont = "arialuni.ttf"
    private let fontsURL = Bundle.main.resourceURL!
    private let asset: AVAsset
    private let player: AVPlayer
    private let renderer: AssSubtitlesRenderer
    private let pipeline: ImagePipelineType
    private let playerItem: AVPlayerItem
    private let subtitleURL: URL
    private let fontProvider: FontProvider
    private let renderKind: RenderKind

    @Environment(\.presentationMode) private var presentationMode: Binding<PresentationMode>

    init(
        asset: AVAsset,
        playerItem: AVPlayerItem,
        subtitleURL: URL,
        fontProvider: FontProvider,
        pipeline: ImagePipelineType,
        renderKind: RenderKind
    ) {
        self.asset = asset
        self.playerItem = playerItem
        self.subtitleURL = subtitleURL
        self.fontProvider = fontProvider
        self.player = AVPlayer(playerItem: playerItem)
        self.renderKind = renderKind
        self.pipeline = pipeline
        self.renderer = AssSubtitlesRenderer(
            fontConfig: FontConfig(
                fontsPath: fontsURL,
                defaultFontName: defaultFont,
                fontProvider: fontProvider
            ),
            pipeline: pipeline,
            logOutput: .console(.verbose)
        )
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
            #if os(visionOS) || os(macOS) || targetEnvironment(macCatalyst)
            .overlay(alignment: .topLeading) {
                Button {
                    presentationMode.wrappedValue.dismiss()
                } label: {
                    Text("Back")
                }
                #if os(visionOS)
                .padding(72)
                #elseif os(macOS) || targetEnvironment(macCatalyst)
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
            if renderKind == .videoOverlay {
                AssSubtitles(renderer: renderer)
                    .attach(player: player, updateInterval: CMTime(value: 1, timescale: 10))
            }
        }
        .aspectRatio(16 / 9, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerSize: CGSize(width: 8, height: 8)))
    }

    private func loadSubtitleTrack() {
        do {
            renderer.loadTrack(content: try String(contentsOf: subtitleURL))
        } catch {
            print(error)
        }
    }

    private func setupPlayer() {
        defer { player.play() }
        guard #available(iOS 16.0, tvOS 16.0, visionOS 1.0, macCatalyst 16.0, macOS 13.0, *) else { return }
        guard renderKind == .videoComposition else { return }
        renderer.attach(to: playerItem, asset: asset)
    }
}

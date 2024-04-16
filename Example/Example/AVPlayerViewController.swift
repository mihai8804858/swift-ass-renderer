#if !os(macOS)
import SwiftUI
import AVKit
import Combine
import SwiftAssRenderer

struct PlayerView: PlatformViewControllerRepresentable {
    let asset: AVAsset
    let playerItem: AVPlayerItem
    let subtitleURL: URL
    let fontProvider: FontProvider
    let pipeline: ImagePipelineType
    let renderKind: RenderKind

    func makeUIViewController(context: Context) -> PlayerViewController {
        PlayerViewController(
            asset: asset,
            playerItem: playerItem,
            subtitleURL: subtitleURL,
            fontProvider: fontProvider,
            pipeline: pipeline,
            renderKind: renderKind
        )
    }

    func updateUIViewController(_ uiViewController: PlayerViewController, context: Context) {}
}

final class PlayerViewController: AVPlayerViewController, AVPlayerViewControllerDelegate {
    private let defaultFont = "arialuni.ttf"
    private let fontsURL = Bundle.main.resourceURL!
    private let asset: AVAsset
    private let playerItem: AVPlayerItem
    private let subtitleURL: URL
    private let fontProvider: FontProvider
    private let renderer: AssSubtitlesRenderer
    private let subtitlesView: AssSubtitlesView
    private let renderKind: RenderKind

    private var cancellables = Set<AnyCancellable>()

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
        self.renderKind = renderKind
        self.renderer = AssSubtitlesRenderer(
            fontConfig: FontConfig(
                fontsPath: fontsURL,
                defaultFontName: defaultFont,
                fontProvider: fontProvider
            ),
            pipeline: pipeline,
            logOutput: .console(.verbose)
        )
        self.subtitlesView = AssSubtitlesView(renderer: renderer)

        super.init(nibName: nil, bundle: nil)

        self.player = AVPlayer(playerItem: playerItem)
        self.allowsPictureInPicturePlayback = true
        #if os(iOS)
        self.canStartPictureInPictureAutomaticallyFromInline = true
        #endif
        self.delegate = self
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        addSubtitlesView()
        loadSubtitleTrack()
        setupPlayer()
    }

    func playerViewControllerRestoreUserInterfaceForPictureInPictureStop(
        _ playerViewController: AVPlayerViewController
    ) async -> Bool {
        return true
    }

    private func addSubtitlesView() {
        guard renderKind == .videoOverlay else { return }
        subtitlesView.attach(to: self, updateInterval: CMTime(value: 1, timescale: 10)) { [weak self] in
            self?.cancellables.insert($0)
        }
    }

    private func loadSubtitleTrack() {
        do {
            renderer.loadTrack(content: try String(contentsOf: subtitleURL))
        } catch {
            print(error)
        }
    }

    private func setupPlayer() {
        defer { player?.play() }
        guard #available(iOS 16.0, tvOS 16.0, visionOS 1.0, macCatalyst 16.0, macOS 13.0, *) else { return }
        guard renderKind == .videoComposition else { return }
        renderer.attach(to: playerItem, asset: asset)
    }
}
#endif

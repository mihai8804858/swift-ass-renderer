#if os(macOS)
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
    @Environment(\.dismiss) private var dismiss

    func makeNSViewController(context: Context) -> PlayerViewController {
        PlayerViewController(
            asset: asset,
            playerItem: playerItem,
            subtitleURL: subtitleURL,
            fontProvider: fontProvider,
            pipeline: pipeline,
            renderKind: renderKind,
            dismiss: dismiss
        )
    }

    func updateNSViewController(_ nsViewController: PlayerViewController, context: Context) {}
}

final class PlayerViewController: PlatformViewController {
    private let defaultFont = "arialuni.ttf"
    private let fontsURL = Bundle.main.resourceURL!
    private let asset: AVAsset
    private let playerItem: AVPlayerItem
    private let subtitleURL: URL
    private let player: AVPlayer
    private let dismiss: DismissAction
    private let fontProvider: FontProvider
    private let renderer: AssSubtitlesRenderer
    private let renderKind: RenderKind
    private let subtitlesView: AssSubtitlesView
    private let playerView = AVPlayerView()
    private var cancellables = Set<AnyCancellable>()

    private lazy var backButton = NSButton(
        title: "Back",
        target: self,
        action: #selector(backTapped)
    )

    @objc private func backTapped() {
        dismiss()
    }

    init(
        asset: AVAsset,
        playerItem: AVPlayerItem,
        subtitleURL: URL,
        fontProvider: FontProvider,
        pipeline: ImagePipelineType,
        renderKind: RenderKind,
        dismiss: DismissAction
    ) {
        self.asset = asset
        self.playerItem = playerItem
        self.subtitleURL = subtitleURL
        self.fontProvider = fontProvider
        self.dismiss = dismiss
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
        self.player = AVPlayer(playerItem: playerItem)

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        addPlayerView()
        addSubtitlesView()
        loadSubtitleTrack()
        setupPlayer()
    }

    private func addPlayerView() {
        view.addSubview(playerView)
        view.addSubview(backButton)
        playerView.player = player
        playerView.clipsToBounds = true
        playerView.layer?.cornerRadius = 8
        playerView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            playerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            playerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            playerView.topAnchor.constraint(equalTo: view.topAnchor),
            playerView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        backButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            backButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            backButton.topAnchor.constraint(equalTo: view.topAnchor, constant: 24)
        ])
    }

    private func addSubtitlesView() {
        guard renderKind == .videoOverlay else { return }
        subtitlesView.attach(
            to: playerView,
            containerView: view,
            updateInterval: CMTime(value: 1, timescale: 10)
        ) { [weak self] in
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
        defer { player.play() }
        guard #available(iOS 16.0, tvOS 16.0, visionOS 1.0, macCatalyst 16.0, macOS 13.0, *) else { return }
        guard renderKind == .videoComposition else { return }
        renderer.attach(to: playerItem, asset: asset)
    }
}
#endif

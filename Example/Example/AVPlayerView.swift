#if os(macOS)
import SwiftUI
import AVKit
import Combine
import SwiftAssRenderer

struct PlayerView: PlatformViewControllerRepresentable {
    let subtitleURL: URL
    let fontProvider: FontProvider
    let pipeline: ImagePipelineType
    @Environment(\.dismiss) private var dismiss

    func makeNSViewController(context: Context) -> PlayerViewController {
        PlayerViewController(
            subtitleURL: subtitleURL,
            fontProvider: fontProvider,
            pipeline: pipeline,
            dismiss: dismiss
        )
    }

    func updateNSViewController(_ nsViewController: PlayerViewController, context: Context) {}
}

final class PlayerViewController: PlatformViewController {
    private let defaultFont = "arialuni.ttf"
    private let videoURL = Bundle.main.url(forResource: "video", withExtension: "mp4")!
    private let fontsURL = Bundle.main.resourceURL!
    private let subtitleURL: URL
    private let player: AVPlayer
    private let dismiss: DismissAction
    private let fontProvider: FontProvider
    private let renderer: AssSubtitlesRenderer
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

    init(subtitleURL: URL, fontProvider: FontProvider, pipeline: ImagePipelineType, dismiss: DismissAction) {
        self.subtitleURL = subtitleURL
        self.fontProvider = fontProvider
        self.dismiss = dismiss
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
        self.player = AVPlayer(url: videoURL)

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
        player.play()
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
}
#endif

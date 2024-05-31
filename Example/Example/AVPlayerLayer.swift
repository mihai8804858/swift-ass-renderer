import Combine
import SwiftUI
import AVKit
import SwiftAssRenderer

struct PlayerLayerView: PlatformViewControllerRepresentable {
    let asset: AVAsset
    let playerItem: AVPlayerItem
    let subtitleURL: URL
    let fontProvider: FontProvider
    let pipeline: ImagePipelineType
    let renderKind: RenderKind
    @Environment(\.dismiss) private var dismiss

    #if os(macOS)
    func makeNSViewController(context: Context) -> PlayerLayerViewController {
        PlayerLayerViewController(
            asset: asset,
            playerItem: playerItem,
            subtitleURL: subtitleURL,
            fontProvider: fontProvider,
            pipeline: pipeline,
            renderKind: renderKind,
            dismiss: dismiss
        )
    }

    func updateNSViewController(_ nsViewController: PlayerLayerViewController, context: Context) {}
    #else
    func makeUIViewController(context: Context) -> PlayerLayerViewController {
        PlayerLayerViewController(
            asset: asset,
            playerItem: playerItem,
            subtitleURL: subtitleURL,
            fontProvider: fontProvider,
            pipeline: pipeline,
            renderKind: renderKind,
            dismiss: dismiss
        )
    }

    func updateUIViewController(_ uiViewController: PlayerLayerViewController, context: Context) {}
    #endif
}

final class PlayerLayerViewController: PlatformViewController {
    final class PlayerView: PlatformView {
        var playerLayer: AVPlayerLayer {
            // swiftlint:disable:next force_cast
            layer as! AVPlayerLayer
        }

        #if !os(macOS)
        override static var layerClass: Swift.AnyClass {
            AVPlayerLayer.self
        }
        #endif

        var player: AVPlayer? {
            get { playerLayer.player }
            set { playerLayer.player = newValue }
        }

        convenience init(player: AVPlayer) {
            self.init()

            #if os(macOS)
            wantsLayer = true
            layer = AVPlayerLayer()
            #endif
            self.player = player
        }

        override init(frame: CGRect) {
            super.init(frame: frame)

            #if os(macOS)
            wantsLayer = true
            layer = AVPlayerLayer()
            #endif
            self.player = AVPlayer()
        }

        required init?(coder aDecoder: NSCoder) {
            super.init(coder: aDecoder)

            #if os(macOS)
            wantsLayer = true
            layer = AVPlayerLayer()
            #endif
            self.player = AVPlayer()
        }
    }

    private let defaultFont = "arialuni.ttf"
    private let fontsURL = Bundle.main.resourceURL!
    private let renderer: AssSubtitlesRenderer
    private let asset: AVAsset
    private let playerItem: AVPlayerItem
    private let subtitleURL: URL
    private let fontProvider: FontProvider
    private let renderKind: RenderKind
    private let dismiss: DismissAction

    private var cancellables = Set<AnyCancellable>()

    private lazy var player = AVPlayer(playerItem: playerItem)
    private lazy var playerView = PlayerView(player: player)
    private lazy var subtitlesView = AssSubtitlesView(renderer: renderer)

    #if os(macOS)
    private lazy var rewindButton = NSButton(
        image: PlatformImage(systemSymbolName: "gobackward.10", accessibilityDescription: nil)!,
        target: self,
        action: #selector(rewindTapped)
    )

    private lazy var forwardButton = NSButton(
        image: PlatformImage(systemSymbolName: "goforward.10", accessibilityDescription: nil)!,
        target: self,
        action: #selector(forwardTapped)
    )

    private lazy var playPauseButton = NSButton(
        image: playPauseImage(player.timeControlStatus)!,
        target: self,
        action: #selector(playPauseTapped)
    )

    private lazy var backButton = NSButton(
        title: "Back",
        target: self,
        action: #selector(backTapped)
    )

    @objc private func rewindTapped() {
        let target = player.currentTime() - CMTime(value: 10, timescale: 1)
        player.seek(to: target < .zero ? .zero : target)
    }

    @objc private func forwardTapped() {
        guard let item = player.currentItem else { return }
        let target = player.currentTime() + CMTime(value: 10, timescale: 1)
        player.seek(to: target > item.duration ? item.duration : target)
    }

    @objc private func playPauseTapped() {
        if player.timeControlStatus == .paused {
            player.play()
        } else {
            player.pause()
        }
    }

    @objc private func backTapped() {
        dismiss()
    }
    #else
    private lazy var rewindButton = UIButton(
        configuration: .plain(),
        primaryAction: UIAction(
            image: UIImage(systemName: "gobackward.10"),
            handler: { [weak self] _ in
                guard let self else { return }
                let target = player.currentTime() - CMTime(value: 10, timescale: 1)
                player.seek(to: target < .zero ? .zero : target)
            }
        )
    )

    private lazy var forwardButton = UIButton(
        configuration: .plain(),
        primaryAction: UIAction(
            image: UIImage(systemName: "goforward.10"),
            handler: { [weak self] _ in
                guard let self, let item = player.currentItem else { return }
                let target = player.currentTime() + CMTime(value: 10, timescale: 1)
                player.seek(to: target > item.duration ? item.duration : target)
            }
        )
    )

    private lazy var playPauseButton = UIButton(
        configuration: .plain(),
        primaryAction: UIAction(
            image: playPauseImage(player.timeControlStatus),
            handler: { [weak self] _ in
                guard let self else { return }
                if player.timeControlStatus == .paused {
                    player.play()
                } else {
                    player.pause()
                }
            }
        )
    )
    #endif

    #if os(visionOS) || targetEnvironment(macCatalyst)
    private lazy var backButton = UIButton(
        configuration: .plain(),
        primaryAction: UIAction(
            title: "Back",
            handler: { [weak self] _ in
                guard let self else { return }
                dismiss()
            }
        )
    )
    #endif

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
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        addPlayerView()
        addSubtitlesView()
        addControls()
        observeTimeControlState()
        loadSubtitleTrack()
        setupPlayer()
        #if os(visionOS)
        preferredContentSize = CGSize(width: 1920, height: 1080)
        #endif
    }

    private func addPlayerView() {
        view.addSubview(playerView)
        playerView.clipsToBounds = true
        playerView.playerLayer.cornerRadius = 8
        playerView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            playerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            playerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            playerView.topAnchor.constraint(equalTo: view.topAnchor),
            playerView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func addSubtitlesView() {
        guard renderKind == .videoOverlay else { return }
        subtitlesView.attach(
            to: playerView.playerLayer,
            containerView: view,
            updateInterval: CMTime(value: 1, timescale: 10),
            storeCancellable: { [weak self] in self?.cancellables.insert($0) }
        )
    }

    private func playPauseImage(_ status: AVPlayer.TimeControlStatus) -> PlatformImage? {
        #if os(macOS)
        if status == .paused {
            return PlatformImage(systemSymbolName: "play.circle", accessibilityDescription: nil)
        } else {
            return PlatformImage(systemSymbolName: "pause.circle", accessibilityDescription: nil)
        }
        #else
        if status == .paused {
            return PlatformImage(systemName: "play.circle")
        } else {
            return PlatformImage(systemName: "pause.circle")
        }
        #endif
    }

    private func addControls() {
        #if os(macOS)
        rewindButton.contentTintColor = .white
        forwardButton.contentTintColor = .white
        playPauseButton.contentTintColor = .white
        #else
        rewindButton.tintColor = .white
        forwardButton.tintColor = .white
        playPauseButton.tintColor = .white
        #endif
        #if os(visionOS) || targetEnvironment(macCatalyst)
        let stackView = UIStackView(arrangedSubviews: [backButton, rewindButton, playPauseButton, forwardButton])
        #elseif os(macOS)
        let stackView = NSStackView(views: [backButton, rewindButton, playPauseButton, forwardButton])
        #else
        let stackView = UIStackView(arrangedSubviews: [rewindButton, playPauseButton, forwardButton])
        #endif
        stackView.translatesAutoresizingMaskIntoConstraints = false
        #if os(macOS)
        view.addSubview(stackView, positioned: .above, relativeTo: subtitlesView)
        #else
        view.insertSubview(stackView, aboveSubview: subtitlesView)
        #endif
        NSLayoutConstraint.activate([
            stackView.centerXAnchor.constraint(equalTo: playerView.centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: playerView.centerYAnchor)
        ])
    }

    private func loadSubtitleTrack() {
        do {
            renderer.loadTrack(content: try String(contentsOf: subtitleURL))
        } catch {
            print(error)
        }
    }

    private func observeTimeControlState() {
        player
            .publisher(for: \.timeControlStatus, options: [.initial, .new])
            .sink { [weak self] _ in
                guard let self else { return }
                #if os(macOS)
                playPauseButton.image = playPauseImage(player.timeControlStatus)
                #else
                playPauseButton.setImage(playPauseImage(player.timeControlStatus), for: .normal)
                #endif
            }.store(in: &cancellables)
    }

    private func setupPlayer() {
        defer { player.play() }
        guard #available(iOS 16.0, tvOS 16.0, visionOS 1.0, macCatalyst 16.0, macOS 13.0, *) else { return }
        guard renderKind == .videoComposition else { return }
        renderer.attach(to: playerItem, asset: asset)
    }
}

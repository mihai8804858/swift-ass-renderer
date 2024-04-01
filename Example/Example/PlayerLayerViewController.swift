#if !os(macOS)
import SwiftUI
import AVKit
import SwiftAssRenderer

struct PlayerLayerView: UIViewControllerRepresentable {
    let subtitleURL: URL
    let fontProvider: FontProvider

    func makeUIViewController(context: Context) -> PlayerLayerViewController {
        PlayerLayerViewController(subtitleURL: subtitleURL, fontProvider: fontProvider)
    }

    func updateUIViewController(_ uiViewController: PlayerLayerViewController, context: Context) {}
}

final class AVPlayerView: UIView {
    var playerLayer: AVPlayerLayer {
        // swiftlint:disable:next force_cast
        layer as! AVPlayerLayer
    }

    override final class var layerClass: Swift.AnyClass {
        AVPlayerLayer.self
    }

    var player: AVPlayer? {
        get { playerLayer.player }
        set { playerLayer.player = newValue }
    }

    convenience init(player: AVPlayer) {
        self.init()

        self.player = player
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        self.player = AVPlayer()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        self.player = AVPlayer()
    }
}

final class PlayerLayerViewController: UIViewController {
    private let defaultFont = "arialuni.ttf"
    private let videoURL = Bundle.main.url(forResource: "video", withExtension: "mp4")!
    private let fontsURL = Bundle.main.resourceURL!
    private let player: AVPlayer
    private let renderer: AssSubtitlesRenderer
    private let subtitleURL: URL
    private let fontProvider: FontProvider

    private var playerConstraints: [NSLayoutConstraint] = []
    private var subtitlesConstraints: [NSLayoutConstraint] = []

    private var boundsObservation: NSKeyValueObservation?
    private var playerItemObservation: NSKeyValueObservation?
    private var presentationSizeObservation: NSKeyValueObservation?
    private var timeControlStatusObservation: NSKeyValueObservation?

    private lazy var playerView = AVPlayerView(player: player)
    private lazy var subtitlesView = AssSubtitlesView(renderer: renderer)

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

    #if os(visionOS)
    private lazy var backButton = UIButton(
        configuration: .plain(),
        primaryAction: UIAction(
            title: "Back",
            handler: { [weak self] _ in
                guard let self else { return }
                dismiss(animated: true)
            }
        )
    )
    #endif

    init(subtitleURL: URL, fontProvider: FontProvider) {
        self.subtitleURL = subtitleURL
        self.fontProvider = fontProvider
        self.player = AVPlayer(url: videoURL)
        self.renderer = AssSubtitlesRenderer(
            fontConfig: FontConfig(
                fontsPath: fontsURL,
                defaultFontName: defaultFont,
                fontProvider: fontProvider
            ),
            logOutput: .console(.verbose)
        )
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupPlayer()
        loadSubtitleTrack()
        addPlayerView()
        addSubtitleView()
        addControls()
        observeBounds()
        observePlayerItem()
        observeTimeControlState()
        #if os(visionOS)
        preferredContentSize = CGSize(width: 1920, height: 1080)
        #endif
    }

    private func setupPlayer() {
        player.play()
        player.addPeriodicTimeObserver(
            forInterval: CMTime(value: 1, timescale: 60),
            queue: .main,
            using: setTimeOffset
        )
    }

    private func playPauseImage(_ status: AVPlayer.TimeControlStatus) -> UIImage? {
        status == .paused ? UIImage(systemName: "play.circle") : UIImage(systemName: "pause.circle")
    }

    private func addControls() {
        rewindButton.tintColor = .white
        forwardButton.tintColor = .white
        playPauseButton.tintColor = .white
        #if os(visionOS)
        let stackView = UIStackView(arrangedSubviews: [backButton, rewindButton, playPauseButton, forwardButton])
        #else
        let stackView = UIStackView(arrangedSubviews: [rewindButton, playPauseButton, forwardButton])
        #endif
        stackView.translatesAutoresizingMaskIntoConstraints = false
        view.insertSubview(stackView, aboveSubview: subtitlesView)
        NSLayoutConstraint.activate([
            stackView.centerXAnchor.constraint(equalTo: playerView.centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: playerView.centerYAnchor)
        ])
    }

    private func setTimeOffset(_ offset: CMTime) {
        renderer.setTimeOffset(offset.seconds)
    }

    private func loadSubtitleTrack() {
        do {
            renderer.loadTrack(content: try String(contentsOf: subtitleURL))
        } catch {
            print(error)
        }
    }

    private func addPlayerView() {
        view.addSubview(playerView)
        layoutPlayerView()
    }

    private func addSubtitleView() {
        view.insertSubview(subtitlesView, aboveSubview: playerView)
        layoutSubtitlesView()
    }

    private func layoutPlayerView() {
        playerView.clipsToBounds = true
        playerView.layer.cornerRadius = 8
        playerView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.deactivate(playerConstraints)
        playerView.removeConstraints(playerConstraints)
        playerConstraints.removeAll()
        if view.bounds.width < view.bounds.height {
            let constraints = [
                playerView.widthAnchor.constraint(equalTo: view.widthAnchor, constant: -16),
                playerView.heightAnchor.constraint(equalTo: playerView.widthAnchor, multiplier: 9 / 16)
            ]
            playerConstraints.append(contentsOf: constraints)
            NSLayoutConstraint.activate(constraints)
        } else {
            let constraints = [
                playerView.heightAnchor.constraint(equalTo: view.heightAnchor, constant: -16),
                playerView.widthAnchor.constraint(equalTo: playerView.heightAnchor, multiplier: 16 / 9)
            ]
            playerConstraints.append(contentsOf: constraints)
            NSLayoutConstraint.activate(constraints)
        }
        let constraints = [
            playerView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            playerView.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ]
        playerConstraints.append(contentsOf: constraints)
        NSLayoutConstraint.activate(constraints)
    }

    private func layoutSubtitlesView() {
        guard let playerItem = player.currentItem,
              !playerView.bounds.size.isEmpty,
              !playerItem.presentationSize.isEmpty else { return }
        subtitlesView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.deactivate(subtitlesConstraints)
        subtitlesView.removeConstraints(subtitlesConstraints)
        subtitlesConstraints.removeAll()
        let subtitlesCanvas = AVMakeRect(
            aspectRatio: playerItem.presentationSize,
            insideRect: playerView.bounds
        )
        subtitlesConstraints.append(contentsOf: [
            subtitlesView.widthAnchor.constraint(equalToConstant: subtitlesCanvas.width),
            subtitlesView.heightAnchor.constraint(equalToConstant: subtitlesCanvas.height),
            subtitlesView.centerXAnchor.constraint(equalTo: playerView.centerXAnchor),
            subtitlesView.centerYAnchor.constraint(equalTo: playerView.centerYAnchor)
        ])
        NSLayoutConstraint.activate(subtitlesConstraints)
    }

    private func observeBounds() {
        boundsObservation?.invalidate()
        boundsObservation = playerView.observe(\.frame, options: [.initial, .new]) { [weak self] _, _ in
            guard let self else { return }
            layoutPlayerView()
            layoutSubtitlesView()
        }
    }

    private func observePlayerItem() {
        playerItemObservation?.invalidate()
        playerItemObservation = player.observe(\.currentItem, options: [.initial, .new]) { [weak self] _, _ in
            guard let self, let item = player.currentItem else { return }
            observePresentationSize(item: item)
        }
    }

    private func observePresentationSize(item: AVPlayerItem) {
        presentationSizeObservation?.invalidate()
        presentationSizeObservation = item.observe(\.presentationSize, options: [.initial, .new]) { [weak self] _, _ in
            guard let self else { return }
            layoutSubtitlesView()
        }
    }

    private func observeTimeControlState() {
        timeControlStatusObservation?.invalidate()
        timeControlStatusObservation = player.observe(\.timeControlStatus) { [weak self] _, _ in
            guard let self else { return }
            playPauseButton.setImage(playPauseImage(player.timeControlStatus), for: .normal)
        }
    }
}

private extension CGSize {
    var isEmpty: Bool {
        width == 0 || height == 0
    }
}
#endif

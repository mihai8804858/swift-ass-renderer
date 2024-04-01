#if !os(macOS)
import SwiftUI
import AVKit
import SwiftAssRenderer

struct PlayerView: UIViewControllerRepresentable {
    let subtitleURL: URL
    let fontProvider: FontProvider

    func makeUIViewController(context: Context) -> PlayerViewController {
        PlayerViewController(subtitleURL: subtitleURL, fontProvider: fontProvider)
    }

    func updateUIViewController(_ uiViewController: PlayerViewController, context: Context) {}
}

final class PlayerViewController: AVPlayerViewController {
    private let defaultFont = "arialuni.ttf"
    private let videoURL = Bundle.main.url(forResource: "video", withExtension: "mp4")!
    private let fontsURL = Bundle.main.resourceURL!
    private let renderer: AssSubtitlesRenderer
    private let subtitleURL: URL
    private let fontProvider: FontProvider

    private var boundsObservation: NSKeyValueObservation?
    private var playerItemObservation: NSKeyValueObservation?
    private var presentationSizeObservation: NSKeyValueObservation?

    private lazy var subtitlesView = AssSubtitlesView(renderer: renderer)

    init(subtitleURL: URL, fontProvider: FontProvider) {
        self.subtitleURL = subtitleURL
        self.fontProvider = fontProvider
        self.renderer = AssSubtitlesRenderer(fontConfig: FontConfig(
            fontsPath: fontsURL,
            defaultFontName: defaultFont,
            fontProvider: fontProvider
        ), logLevel: .verbose)

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupPlayer()
        loadSubtitleTrack()
        addSubtitleView()
        observeBounds()
        observePlayerItem()
    }

    override func viewWillTransition(to size: CGSize, with coordinator: any UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        coordinator.animate { [weak self] _ in
            self?.layoutSubtitlesView()
            self?.contentOverlayView?.layoutSubviews()
        }
    }

    private func setupPlayer() {
        player = AVPlayer(url: videoURL)
        player?.play()
        player?.addPeriodicTimeObserver(
            forInterval: CMTime(value: 1, timescale: 60),
            queue: .main,
            using: setTimeOffset
        )
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

    private func addSubtitleView() {
        contentOverlayView?.addSubview(subtitlesView)
        layoutSubtitlesView()
    }

    private func layoutSubtitlesView() {
        guard let contentOverlayView,
              let playerItem = player?.currentItem,
              !contentOverlayView.bounds.isEmpty,
              !playerItem.presentationSize.isEmpty else { return }
        subtitlesView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.deactivate(subtitlesView.constraints)
        subtitlesView.removeConstraints(subtitlesView.constraints)
        let subtitlesCanvas = AVMakeRect(
            aspectRatio: playerItem.presentationSize,
            insideRect: contentOverlayView.bounds
        )
        NSLayoutConstraint.activate([
            subtitlesView.widthAnchor.constraint(equalToConstant: subtitlesCanvas.width),
            subtitlesView.heightAnchor.constraint(equalToConstant: subtitlesCanvas.height),
            subtitlesView.centerXAnchor.constraint(equalTo: contentOverlayView.centerXAnchor),
            subtitlesView.centerYAnchor.constraint(equalTo: contentOverlayView.centerYAnchor)
        ])
    }

    private func observeBounds() {
        boundsObservation?.invalidate()
        boundsObservation = contentOverlayView?.observe(\.frame, options: [.initial, .new]) { [weak self] _, _ in
            guard let self else { return }
            layoutSubtitlesView()
        }
    }

    private func observePlayerItem() {
        playerItemObservation?.invalidate()
        playerItemObservation = player?.observe(\.currentItem, options: [.initial, .new]) { [weak self] _, _ in
            guard let self, let item = player?.currentItem else { return }
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
}

private extension CGSize {
    var isEmpty: Bool {
        width == 0 || height == 0
    }
}
#endif

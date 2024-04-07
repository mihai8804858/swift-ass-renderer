import AppKit
import AVKit
import Combine
import SwiftAssRenderer

final class VideoPlayerViewController: NSViewController {
    private let player = AVPlayer(url: ...)
    private let renderer = AssSubtitlesRenderer(fontConfig: FontConfig(fontsPath: ...))
    private let playerView = AVPlayerView()
    private lazy var subtitlesView = AssSubtitlesView(renderer: renderer)
    private var cancellables = Set<AnyCancellable>()

    override func viewDidLoad() {
        super.viewDidLoad()

        playerView.player = player
        addPlayerView()
        addSubtitlesView()
        loadSubtitleTrack()
    }

    private func addPlayerView() {
        view.addSubview(playerView)
        playerView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            playerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            playerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            playerView.topAnchor.constraint(equalTo: view.topAnchor),
            playerView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func addSubtitlesView() {
        subtitlesView.attach(
            to: playerView,
            containerView: view,
            updateInterval: CMTime(value: 1, timescale: 10),
            storeCancellable: { [weak self] in self?.cancellables.insert($0) }
        )
    }

    private func loadSubtitleTrack() {

    }
}

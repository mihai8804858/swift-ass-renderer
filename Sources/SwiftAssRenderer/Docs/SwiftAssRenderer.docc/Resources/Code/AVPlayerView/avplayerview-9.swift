import AppKit
import AVKit
import SwiftAssRenderer

final class VideoPlayerViewController: NSViewController {
    private let player = AVPlayer(url: ...)
    private let renderer = AssSubtitlesRenderer(fontConfig: FontConfig(fontsPath: ...))
    private let playerView = AVPlayerView()
    private lazy var subtitlesView = AssSubtitlesView(renderer: renderer)

    override func viewDidLoad() {
        super.viewDidLoad()

        playerView.player = player
        addPlayerView()
        addSubtitlesView()
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

    }
}

import UIKit
import Combine
import AVFoundation
import SwiftAssRenderer

final class VideoPlayerView: UIView {
    var playerLayer: AVPlayerLayer {
        layer as! AVPlayerLayer
    }

    override final class var layerClass: Swift.AnyClass {
        AVPlayerLayer.self
    }

    convenience init(player: AVPlayer) {
        self.init()

        playerLayer.player = player
    }
}

final class VideoPlayerViewController: UIViewController {
    private let player = AVPlayer(url: ...)
    private let renderer = AssSubtitlesRenderer(fontConfig: FontConfig(fontsPath: ...))
    private lazy var playerView = VideoPlayerView(player: player)
    private lazy var subtitlesView = AssSubtitlesView(renderer: renderer)
    private var cancellables = Set<AnyCancellable>()

    override func viewDidLoad() {
        super.viewDidLoad()

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
            to: playerView.playerLayer,
            containerView: view,
            updateInterval: CMTime(value: 1, timescale: 10),
            storeCancellable: { [weak self] in self?.cancellables.insert($0) }
        )
    }

    private func loadSubtitleTrack() {
        Task {
            do {
                let contents = try await ...
                renderer.loadTrack(content: contents)
            } catch {
                print(error)
            }
        }
    }
}

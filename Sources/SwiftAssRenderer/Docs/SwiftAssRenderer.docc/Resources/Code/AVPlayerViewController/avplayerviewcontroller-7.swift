import UIKit
import AVKit
import AVFoundation
import Combine
import SwiftAssRenderer

final class VideoPlayerViewController: AVPlayerViewController {
    private let renderer = AssSubtitlesRenderer(fontConfig: FontConfig(fontsPath: ...))
    private lazy var subtitlesView = AssSubtitlesView(renderer: renderer)
    private var cancellables = Set<AnyCancellable>()

    override func viewDidLoad() {
        super.viewDidLoad()

        player = AVPlayer(url: ...)
        addSubtitlesView()
        loadSubtitleTrack()
    }

    private func addSubtitlesView() {
        subtitlesView.attach(
            to: self,
            updateInterval: CMTime(value: 1, timescale: 10),
            storeCancellable: { [weak self] in self?.cancellables.insert($0) }
        )
    }

    private func loadSubtitleTrack() {
        
    }
}

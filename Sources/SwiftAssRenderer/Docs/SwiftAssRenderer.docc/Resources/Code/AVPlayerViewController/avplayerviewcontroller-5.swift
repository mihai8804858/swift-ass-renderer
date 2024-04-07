import UIKit
import AVKit
import AVFoundation
import SwiftAssRenderer

final class VideoPlayerViewController: AVPlayerViewController {
    private let renderer = AssSubtitlesRenderer(fontConfig: FontConfig(fontsPath: ...))
    private lazy var subtitlesView = AssSubtitlesView(renderer: renderer)

    override func viewDidLoad() {
        super.viewDidLoad()

        player = AVPlayer(url: ...)
        addSubtitlesView()
    }

    private func addSubtitlesView() {
    }
}

import UIKit
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
}

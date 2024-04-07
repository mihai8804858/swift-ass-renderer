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

}

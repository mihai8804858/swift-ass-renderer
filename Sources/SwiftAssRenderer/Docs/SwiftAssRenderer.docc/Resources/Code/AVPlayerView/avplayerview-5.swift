import AppKit
import AVKit
import SwiftAssRenderer

final class VideoPlayerViewController: NSViewController {
    private let player = AVPlayer(url: ...)
    private let renderer = AssSubtitlesRenderer(fontConfig: FontConfig(fontsPath: ...))
    private let playerView = AVPlayerView()
    private lazy var subtitlesView = AssSubtitlesView(renderer: renderer)
}

import UIKit
import AVKit
import AVFoundation
import SwiftAssRenderer

final class VideoPlayerViewController: AVPlayerViewController {
    private let renderer = AssSubtitlesRenderer(fontConfig: FontConfig(fontsPath: ...))
}

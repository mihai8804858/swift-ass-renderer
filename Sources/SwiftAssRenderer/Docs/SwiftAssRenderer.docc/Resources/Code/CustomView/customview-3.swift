import UIKit
import SwiftAssRenderer

final class SubtitlesViewController: UIViewController {
    private let renderer = AssSubtitlesRenderer(fontConfig: FontConfig(fontsPath: ...))
    private lazy var subtitlesView = AssSubtitlesView(renderer: renderer)
}

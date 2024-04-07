import UIKit
import SwiftAssRenderer

final class SubtitlesViewController: UIViewController {
    private let renderer = AssSubtitlesRenderer(fontConfig: FontConfig(fontsPath: ...))

    override func viewDidLoad() {
        super.viewDidLoad()
    }
}

import UIKit
import SwiftAssRenderer

final class SubtitlesViewController: UIViewController {
    private let renderer = AssSubtitlesRenderer(fontConfig: FontConfig(fontsPath: ...))

    override func viewDidLoad() {
        super.viewDidLoad()

        loadSubtitleTrack()
    }

    private func loadSubtitleTrack() {
        Task {
            do {
                let contents = try await ...
            } catch {
                print(error)
            }
        }
    }
}

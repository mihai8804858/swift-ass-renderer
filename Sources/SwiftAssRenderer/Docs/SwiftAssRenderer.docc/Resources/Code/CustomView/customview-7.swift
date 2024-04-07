import UIKit
import SwiftAssRenderer

final class SubtitlesViewController: UIViewController {
    private let renderer = AssSubtitlesRenderer(fontConfig: FontConfig(fontsPath: ...))
    private lazy var subtitlesView = AssSubtitlesView(renderer: renderer)

    override func viewDidLoad() {
        super.viewDidLoad()

        addSubtitlesView()
        loadSubtitleTrack()
    }

    private func addSubtitlesView() {
        view.addSubview(subtitlesView)
        subtitlesView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            subtitlesView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            subtitlesView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            subtitlesView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            subtitlesView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }

    private func loadSubtitleTrack() {

    }
}

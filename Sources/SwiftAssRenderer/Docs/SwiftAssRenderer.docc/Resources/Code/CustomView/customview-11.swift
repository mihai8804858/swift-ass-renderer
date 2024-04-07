import UIKit
import Combine
import SwiftAssRenderer

final class SubtitlesViewController: UIViewController {
    private let renderer = AssSubtitlesRenderer(fontConfig: FontConfig(fontsPath: ...))
    private lazy var subtitlesView = AssSubtitlesView(renderer: renderer)
    private var cancellables = Set<AnyCancellable>()

    override func viewDidLoad() {
        super.viewDidLoad()

        addSubtitlesView()
        loadSubtitleTrack()
        setupSubtitlesTimer()
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
        Task {
            do {
                let contents = try await ...
                renderer.loadTrack(content: contents)
            } catch {
                print(error)
            }
        }
    }

    private func setupSubtitlesTimer() {
        Timer
            .publish(every: 0.1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] date in

            }
            .store(in: &cancellables)
    }
}

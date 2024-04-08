#if !os(macOS)
import SwiftUI
import AVKit
import Combine
import SwiftAssRenderer

struct PlayerView: PlatformViewControllerRepresentable {
    let subtitleURL: URL
    let fontProvider: FontProvider
    let pipeline: ImagePipelineType

    func makeUIViewController(context: Context) -> PlayerViewController {
        PlayerViewController(subtitleURL: subtitleURL, fontProvider: fontProvider, pipeline: pipeline)
    }

    func updateUIViewController(_ uiViewController: PlayerViewController, context: Context) {}
}

final class PlayerViewController: AVPlayerViewController {
    private let defaultFont = "arialuni.ttf"
    private let videoURL = Bundle.main.url(forResource: "video", withExtension: "mp4")!
    private let fontsURL = Bundle.main.resourceURL!
    private let subtitleURL: URL
    private let fontProvider: FontProvider
    private let renderer: AssSubtitlesRenderer
    private let subtitlesView: AssSubtitlesView

    private var cancellables = Set<AnyCancellable>()

    init(subtitleURL: URL, fontProvider: FontProvider, pipeline: ImagePipelineType) {
        self.subtitleURL = subtitleURL
        self.fontProvider = fontProvider
        self.renderer = AssSubtitlesRenderer(
            fontConfig: FontConfig(
                fontsPath: fontsURL,
                defaultFontName: defaultFont,
                fontProvider: fontProvider
            ),
            pipeline: pipeline,
            logOutput: .console(.verbose)
        )
        self.subtitlesView = AssSubtitlesView(renderer: renderer)

        super.init(nibName: nil, bundle: nil)

        self.player = AVPlayer(url: videoURL)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        addSubtitlesView()
        loadSubtitleTrack()
        player?.play()
    }

    private func addSubtitlesView() {
        subtitlesView.attach(to: self, updateInterval: CMTime(value: 1, timescale: 10)) { [weak self] in
            self?.cancellables.insert($0)
        }
    }

    private func loadSubtitleTrack() {
        do {
            renderer.loadTrack(content: try String(contentsOf: subtitleURL))
        } catch {
            print(error)
        }
    }
}
#endif

import SwiftUI
import AVKit

public extension AssSubtitles {
    /// Attach this subtitles view to `player` by updating the renderer offset each `updateInterval`.
    ///
    /// - Parameters:
    ///   - player: Player to observe the `presentationSize` and `currentTime` from.
    ///   - updateInterval: How fast to update the renderer time offset.
    ///
    /// This method also:
    /// - Lays out the subtitles each time view frame changes or
    /// `presentationSize` of currently playing item changes.
    /// - Frees current subtitles track when player's `currentItem` changes to `nil`.
    /// - Periodically updates renderer time offset each `updateInterval`.
    func attach(player: AVPlayer, updateInterval: CMTime) -> some View {
        modifier(AssSubtitlesAttachModifier(
            player: player,
            renderer: renderer,
            updateInterval: updateInterval
        ))
    }
}

struct AssSubtitlesAttachModifier: ViewModifier {
    let player: AVPlayer
    let renderer: AssSubtitlesRenderer
    let updateInterval: CMTime

    @State private var viewSize: CGSize = .zero
    @State private var videoSize: CGSize = .zero
    @State private var subtitlesSize: CGSize?

    func body(content: Content) -> some View {
        content
            .readSize(in: $viewSize)
            .ifLet(subtitlesSize) { view, size in
                view
                    .frame(width: size.width, height: size.height, alignment: .center)
                    .fixedSize()
            }
            .onReceive(
                player.publisher(for: \.currentItem?.presentationSize, options: [.initial, .new]),
                perform: presentationSizeChanged
            )
            .onReceive(
                player.periodicTimeObserver(interval: updateInterval),
                perform: { [weak renderer] in renderer?.setTimeOffset($0.seconds) }
            )
    }

    private func presentationSizeChanged(to size: CGSize?) {
        if let size {
            videoSize = size
            guard !viewSize.isEmpty, !videoSize.isEmpty else { return }
            subtitlesSize = AVMakeRect(
                aspectRatio: videoSize,
                insideRect: CGRect(origin: .zero, size: viewSize)
            ).size
        } else {
            renderer.freeTrack()
        }
    }
}

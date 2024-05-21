#if os(macOS)
import AVKit
import AVFoundation
import Combine

public extension AssSubtitlesView {
    /// Attach this subtitles view to `containerView` by adding it as a subview 
    /// and update the renderer offset each `updateInterval`.
    ///
    /// - Parameters:
    ///   - playerView: Player view to observe (`player` property should already be set when calling this).
    ///   - containerView: View on which to add the subtitles view as a subview. This view should be above `playerView`.
    ///   - updateInterval: How fast to update the renderer time offset.
    ///   - storeCancellable: Callback to store a Combine cancellable.
    ///   Client needs to store each cancellable sent in this closure otherwise no updated will happen.
    ///
    /// Besides adding the view as a subview to `containerView`, this method also:
    /// - Lays out the subtitles view each time `containerView` frame changes or player view's `videoBounds` changes.
    /// - Frees current subtitles track when player's `currentItem` changes to `nil`.
    /// - Periodically updates renderer time offset each `updateInterval`.
    func attach(
        to playerView: AVPlayerView,
        containerView: PlatformView,
        updateInterval: CMTime,
        storeCancellable: @escaping (AnyCancellable) -> Void
    ) {
        containerView.addSubview(self)
        layout(playerView: playerView, containerView: containerView)
        observeContainerFrame(
            playerView: playerView,
            containerView: containerView,
            storeCancellable: storeCancellable
        )
        observeVideoBounds(
            playerView: playerView,
            containerView: containerView,
            storeCancellable: storeCancellable
        )
        observePlayerItem(
            playerView: playerView,
            storeCancellable: storeCancellable
        )
        observeTimeOffset(
            playerView: playerView,
            interval: updateInterval,
            storeCancellable: storeCancellable
        )
    }
}

private extension AssSubtitlesView {
    func layout(playerView: AVPlayerView, containerView: PlatformView) {
        guard !containerView.bounds.size.isEmpty, !playerView.videoBounds.isEmpty else { return }
        translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.deactivate(constraints)
        removeConstraints(constraints)
        NSLayoutConstraint.activate([
            widthAnchor.constraint(equalToConstant: playerView.videoBounds.width),
            heightAnchor.constraint(equalToConstant: playerView.videoBounds.height),
            centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            centerYAnchor.constraint(equalTo: containerView.centerYAnchor)
        ])
    }

    func observeContainerFrame(
        playerView: AVPlayerView,
        containerView: PlatformView,
        storeCancellable: @escaping (AnyCancellable) -> Void
    ) {
        let cancellable = containerView
            .publisher(for: \.frame, options: [.initial, .new])
            .receive(on: DispatchQueue.main)
            .sink { [weak self, weak playerView, weak containerView] _ in
                guard let self, let playerView, let containerView else { return }
                layout(playerView: playerView, containerView: containerView)
            }
        storeCancellable(cancellable)
    }

    func observePlayerItem(
        playerView: AVPlayerView,
        storeCancellable: @escaping (AnyCancellable) -> Void
    ) {
        guard let player = playerView.player else { return }
        let cancellable = player
            .publisher(for: \.currentItem, options: [.initial, .new])
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self else { return }
                if player.currentItem == nil { renderer.freeTrack() }
            }
        storeCancellable(cancellable)
    }

    func observeVideoBounds(
        playerView: AVPlayerView,
        containerView: PlatformView,
        storeCancellable: @escaping (AnyCancellable) -> Void
    ) {
        let cancellable = playerView
            .publisher(for: \.videoBounds, options: [.initial, .new])
            .receive(on: DispatchQueue.main)
            .sink { [weak self, weak playerView, weak containerView] _ in
                guard let self, let playerView, let containerView else { return }
                layout(playerView: playerView, containerView: containerView)
            }
        storeCancellable(cancellable)
    }

    func observeTimeOffset(
        playerView: AVPlayerView,
        interval: CMTime,
        storeCancellable: @escaping (AnyCancellable) -> Void
    ) {
        guard let player = playerView.player else { return }
        let cancellable = player
            .periodicTimeObserver(interval: interval)
            .sink { [weak self] time in
                guard let self else { return }
                renderer.setTimeOffset(time.seconds)
            }
        storeCancellable(cancellable)
    }
}
#endif

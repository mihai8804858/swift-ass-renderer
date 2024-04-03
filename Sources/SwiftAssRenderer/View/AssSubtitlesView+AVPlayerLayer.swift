import AVKit
import AVFoundation
import Combine

public extension AssSubtitlesView {
    /// Attach this subtitles view to `containerView` by adding it as a subview 
    /// and update the renderer offset each `updateInterval`.
    ///
    /// - Parameters:
    ///   - layer: Player layer to observe (`player` property should already be set when calling this).
    ///   - containerView: View on which to add the subtitles view as a subview. This view should be above `layer`.
    ///   - updateInterval: How fast to update the renderer time offset.
    ///   - storeCancellable: Callback to store a Combine cancellable.
    ///   Client needs to store each cancellable sent in this closure otherwise no updated will happen.
    ///
    /// Besides adding the view as a subview to `containerView`, this method also:
    /// - Lays out the subtitles view each time `containerView` frame changes
    /// or `presentationSize` of currently playing item changes.
    /// - Frees current subtitles track when player's `currentItem` changes to `nil`.
    /// - Periodically updates renderer time offset each `updateInterval`.
    func attach(
        to layer: AVPlayerLayer,
        containerView: PlatformView,
        updateInterval: CMTime,
        storeCancellable: @escaping (AnyCancellable) -> Void
    ) {
        containerView.addSubview(self)
        layout(layer: layer, containerView: containerView)
        observeContainerFrame(
            layer: layer,
            containerView: containerView,
            storeCancellable: storeCancellable
        )
        observePlayerItem(
            layer: layer,
            containerView: containerView,
            storeCancellable: storeCancellable
        )
        observeTimeOffset(
            layer: layer,
            interval: updateInterval,
            storeCancellable: storeCancellable
        )
    }
}

private extension AssSubtitlesView {
    func layout(layer: AVPlayerLayer, containerView: PlatformView) {
        guard let playerItem = layer.player?.currentItem,
              !containerView.bounds.size.isEmpty,
              !playerItem.presentationSize.isEmpty else { return }
        translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.deactivate(constraints)
        removeConstraints(constraints)
        let subtitlesCanvas = AVMakeRect(
            aspectRatio: playerItem.presentationSize,
            insideRect: containerView.bounds
        )
        NSLayoutConstraint.activate([
            widthAnchor.constraint(equalToConstant: subtitlesCanvas.width),
            heightAnchor.constraint(equalToConstant: subtitlesCanvas.height),
            centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            centerYAnchor.constraint(equalTo: containerView.centerYAnchor)
        ])
    }

    func observeContainerFrame(
        layer: AVPlayerLayer,
        containerView: PlatformView,
        storeCancellable: @escaping (AnyCancellable) -> Void
    ) {
        let cancellable = containerView
            .publisher(for: \.frame, options: [.initial, .new])
            .sink { [weak self, weak layer, weak containerView] _ in
                guard let self, let layer, let containerView else { return }
                layout(layer: layer, containerView: containerView)
            }
        storeCancellable(cancellable)
    }

    func observePlayerItem(
        layer: AVPlayerLayer,
        containerView: PlatformView,
        storeCancellable: @escaping (AnyCancellable) -> Void
    ) {
        guard let player = layer.player else { return }
        let cancellable = player
            .publisher(for: \.currentItem, options: [.initial, .new])
            .sink { [weak self, weak layer, weak containerView] _ in
                guard let self, let layer, let containerView else { return }
                if let item = player.currentItem {
                    observePresentationSize(
                        layer: layer,
                        containerView: containerView,
                        item: item,
                        storeCancellable: storeCancellable
                    )
                } else {
                    renderer.freeTrack()
                }
            }
        storeCancellable(cancellable)
    }

    func observePresentationSize(
        layer: AVPlayerLayer,
        containerView: PlatformView,
        item: AVPlayerItem,
        storeCancellable: @escaping (AnyCancellable) -> Void
    ) {
        let cancellable = item
            .publisher(for: \.presentationSize, options: [.initial, .new])
            .sink { [weak self, weak layer, weak containerView] _ in
                guard let self, let layer, let containerView else { return }
                layout(layer: layer, containerView: containerView)
            }
        storeCancellable(cancellable)
    }

    func observeTimeOffset(
        layer: AVPlayerLayer,
        interval: CMTime,
        storeCancellable: @escaping (AnyCancellable) -> Void
    ) {
        guard let player = layer.player else { return }
        let cancellable = player
            .periodicTimeObserver(interval: interval)
            .sink { [weak self] time in
                guard let self else { return }
                renderer.setTimeOffset(time.seconds)
            }
        storeCancellable(cancellable)
    }
}

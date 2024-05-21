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
        to playerLayer: AVPlayerLayer,
        containerView: PlatformView,
        updateInterval: CMTime,
        storeCancellable: @escaping (AnyCancellable) -> Void
    ) {
        containerView.addSubview(self)
        layout(layer: playerLayer)
        observeLayerFrame(layer: playerLayer, storeCancellable: storeCancellable)
        observePlayerItem(layer: playerLayer, storeCancellable: storeCancellable)
        observeTimeOffset(layer: playerLayer, interval: updateInterval, storeCancellable: storeCancellable)
    }
}

private extension AssSubtitlesView {
    func layout(layer: AVPlayerLayer) {
        guard let playerItem = layer.player?.currentItem, !playerItem.presentationSize.isEmpty else { return }
        translatesAutoresizingMaskIntoConstraints = false
        frame = AVMakeRect(
            aspectRatio: playerItem.presentationSize,
            insideRect: layer.bounds
        ).applying(.identity.translatedBy(
            x: layer.frame.minX,
            y: layer.frame.minY
        ).scaledBy(
            x: layer.affineTransform().a,
            y: layer.affineTransform().d
        ))
    }

    func observeLayerFrame(
        layer: AVPlayerLayer,
        storeCancellable: @escaping (AnyCancellable) -> Void
    ) {
        layer.onFrameChanged { [weak self, weak layer] in
            guard let self, let layer else { return }
            layout(layer: layer)
        } storeCancellable: { cancellable in
            storeCancellable(cancellable)
        }
    }

    func observePlayerItem(
        layer: AVPlayerLayer,
        storeCancellable: @escaping (AnyCancellable) -> Void
    ) {
        guard let player = layer.player else { return }
        let cancellable = player
            .publisher(for: \.currentItem, options: [.initial, .new])
            .receive(on: DispatchQueue.main)
            .sink { [weak self, weak layer] _ in
                guard let self, let layer else { return }
                if let item = player.currentItem {
                    observePresentationSize(layer: layer, item: item, storeCancellable: storeCancellable)
                } else {
                    renderer.freeTrack()
                }
            }
        storeCancellable(cancellable)
    }

    func observePresentationSize(
        layer: AVPlayerLayer,
        item: AVPlayerItem,
        storeCancellable: @escaping (AnyCancellable) -> Void
    ) {
        let cancellable = item
            .publisher(for: \.presentationSize, options: [.initial, .new])
            .receive(on: DispatchQueue.main)
            .sink { [weak self, weak layer] _ in
                guard let self, let layer else { return }
                layout(layer: layer)
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

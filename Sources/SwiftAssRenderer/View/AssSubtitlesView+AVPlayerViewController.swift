#if !os(macOS)
import AVKit
import AVFoundation
import Combine

public extension AssSubtitlesView {
    /// Attach this subtitles view to `contentOverlayView` from `viewController` by adding it as a subview
    /// and update the renderer offset each `updateInterval`.
    ///
    /// - Parameters:
    ///   - viewController: Player view controller to observe.
    ///   `player` property should already be set when calling this.
    ///   - updateInterval: How fast to update the renderer time offset.
    ///   - storeCancellable: Callback to store a Combine cancellable.
    ///   Client needs to store each cancellable sent in this closure otherwise no updated will happen.
    ///
    /// Besides adding the view as a subview to `contentOverlayView`, this method also:
    /// - Lays out the subtitles view each time `contentOverlayView` frame changes or
    /// view controller's `videoBounds` changes.
    /// - Frees current subtitles track when player's `currentItem` changes to `nil`.
    /// - Periodically updates renderer time offset each `updateInterval`.
    func attach(
        to viewController: AVPlayerViewController,
        updateInterval: CMTime,
        storeCancellable: @escaping (AnyCancellable) -> Void
    ) {
        guard let contentOverlayView = viewController.contentOverlayView else { return }
        contentOverlayView.addSubview(self)
        layout(viewController: viewController)
        observeOverlayFrame(
            viewController: viewController,
            storeCancellable: storeCancellable
        )
        observePlayerItem(
            viewController: viewController,
            storeCancellable: storeCancellable
        )
        observeTimeOffset(
            viewController: viewController,
            interval: updateInterval,
            storeCancellable: storeCancellable
        )
    }
}

private extension AssSubtitlesView {
    func layout(viewController: AVPlayerViewController) {
        guard let playerItem = viewController.player?.currentItem,
              let contentOverlayView = viewController.contentOverlayView else { return }
        let videoSize = {
            #if os(tvOS)
            AVMakeRect(
                aspectRatio: playerItem.presentationSize,
                insideRect: contentOverlayView.bounds
            )
            #else
            viewController.videoBounds.size
            #endif
        }()
        guard !contentOverlayView.bounds.isEmpty, !videoSize.isEmpty else { return }
        translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.deactivate(constraints)
        removeConstraints(constraints)
        let overlayOrigin = contentOverlayView.convert(
            contentOverlayView.frame.origin,
            to: viewController.view
        )
        let xOffset = -(overlayOrigin.x / 2)
        let yOffset = -(overlayOrigin.y / 2)
        NSLayoutConstraint.activate([
            widthAnchor.constraint(equalToConstant: videoSize.width),
            heightAnchor.constraint(equalToConstant: videoSize.height),
            centerXAnchor.constraint(equalTo: contentOverlayView.centerXAnchor, constant: xOffset),
            centerYAnchor.constraint(equalTo: contentOverlayView.centerYAnchor, constant: yOffset)
        ])
    }

    func observeOverlayFrame(
        viewController: AVPlayerViewController,
        storeCancellable: @escaping (AnyCancellable) -> Void
    ) {
        guard let contentOverlayView = viewController.contentOverlayView else { return }
        let cancellable = contentOverlayView
            .publisher(for: \.frame, options: [.initial, .new])
            .sink { [weak self, weak viewController] _ in
                guard let self, let viewController else { return }
                layout(viewController: viewController)
            }
        storeCancellable(cancellable)
    }

    func observePlayerItem(
        viewController: AVPlayerViewController,
        storeCancellable: @escaping (AnyCancellable) -> Void
    ) {
        guard let player = viewController.player else { return }
        let cancellable = player
            .publisher(for: \.currentItem, options: [.initial, .new])
            .sink { [weak self, weak viewController] _ in
                guard let self, let viewController else { return }
                if let item = player.currentItem {
                    observeVideoBounds(
                        viewController: viewController,
                        playerItem: item,
                        storeCancellable: storeCancellable
                    )
                } else {
                    renderer.freeTrack()
                }
            }
        storeCancellable(cancellable)
    }

    func observeVideoBounds(
        viewController: AVPlayerViewController,
        playerItem: AVPlayerItem,
        storeCancellable: @escaping (AnyCancellable) -> Void
    ) {
        #if os(tvOS)
        let cancellable = playerItem
            .publisher(for: \.presentationSize, options: [.initial, .new])
            .sink { [weak self, weak viewController] _ in
                guard let self, let viewController else { return }
                layout(viewController: viewController)
            }
        storeCancellable(cancellable)
        #else
        let cancellable = viewController
            .publisher(for: \.videoBounds, options: [.initial, .new])
            .sink { [weak self, weak viewController] _ in
                guard let self, let viewController else { return }
                layout(viewController: viewController)
            }
        storeCancellable(cancellable)
        #endif
    }

    func observeTimeOffset(
        viewController: AVPlayerViewController,
        interval: CMTime,
        storeCancellable: @escaping (AnyCancellable) -> Void
    ) {
        guard let player = viewController.player else { return }
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

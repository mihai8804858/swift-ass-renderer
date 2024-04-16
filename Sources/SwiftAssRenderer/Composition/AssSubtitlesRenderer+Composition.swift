#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif
import AVFoundation

@available(iOS 16.0, tvOS 16.0, visionOS 1.0, macCatalyst 16.0, macOS 13.0, *)
public extension AssSubtitlesRenderer {
    #if canImport(UIKit)
    /// Attach this subtitles renderer to `playerItem` and `asset`
    /// by setting the player item's `videoComposition` to a compositor that
    /// that can render both video and subtitles at the same time.
    ///
    /// - Parameters:
    ///   - playerItem: Player item where to render the subtitles.
    ///   - asset: Player asset used for rendering the source audio / video tracks.
    ///   - scale: Screen scale. Bigger scale results in sharper images, but lower performance.
    ///
    /// **Important:** Video composition rendering does not work for HLS streams.
    ///
    /// **Important:** When using composition rendering, you should not call either `setCanvasSize(_:scale:)` 
    /// or `setTimeOffset(_:)`
    /// methods as this will be done automatically by the video compositor.
    func attach(
        to playerItem: AVPlayerItem,
        asset: AVAsset,
        scale: CGFloat = UITraitCollection.current.displayScale
    ) {
        performAttachment(to: playerItem, asset: asset, scale: scale)
    }
    #elseif canImport(AppKit)
    /// Attach this subtitles renderer to `playerItem` and `asset`
    /// by setting the player item's `videoComposition` to a compositor that
    /// that can render both video and subtitles at the same time.
    ///
    /// - Parameters:
    ///   - playerItem: Player item where to render the subtitles.
    ///   - asset: Player asset used for rendering the source audio / video tracks.
    ///   - scale: Screen scale. Bigger scale results in sharper images, but lower performance.
    ///
    /// **Important:** Video composition rendering does not work for HLS streams.
    ///
    /// **Important:** When using composition rendering, you should not call either `setCanvasSize(_:scale:)`
    /// or `setTimeOffset(_:)`
    /// methods as this will be done automatically by the video compositor.
    func attach(
        to playerItem: AVPlayerItem,
        asset: AVAsset,
        scale: CGFloat = 2.0
    ) {
        performAttachment(to: playerItem, asset: asset, scale: scale)
    }
    #endif

    private func performAttachment(to playerItem: AVPlayerItem, asset: AVAsset, scale: CGFloat) {
        Task { @MainActor in
            let composition = AssVideoComposition(asset: asset, renderer: self, scale: scale)
            playerItem.videoComposition = try await composition.makeAVVideoComposition()
        }
    }
}

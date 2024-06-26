import SwiftUI

/// SwiftUI `View` capable or drawing rendered image bitmaps to the screen, by subscribing to ``AssSubtitlesRenderer``
/// events and rendering output ``ProcessedImage`` in a image view.
public struct AssSubtitles: PlatformViewRepresentable {
    let renderer: AssSubtitlesRenderer
    let scale: CGFloat

    #if canImport(UIKit)
    public init(renderer: AssSubtitlesRenderer, scale: CGFloat = UITraitCollection.current.displayScale) {
        self.renderer = renderer
        self.scale = scale
    }

    public func makeUIView(context: Context) -> AssSubtitlesView {
        AssSubtitlesView(renderer: renderer, scale: scale)
    }

    public func updateUIView(_ uiView: AssSubtitlesView, context: Context) {
        uiView.renderer.reloadFrame()
    }
    #elseif canImport(AppKit)
    public init(renderer: AssSubtitlesRenderer, scale: CGFloat = 2.0) {
        self.renderer = renderer
        self.scale = scale
    }

    public func makeNSView(context: Context) -> AssSubtitlesView {
        AssSubtitlesView(renderer: renderer, scale: scale)
    }

    public func updateNSView(_ nsView: AssSubtitlesView, context: Context) {
        nsView.renderer.reloadFrame()
    }
    #endif
}

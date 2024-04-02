import SwiftUI

/// SwiftUI `View` capable or drawing rendered image bitmaps to the screen, by subscriging to ``AssSubtitlesRenderer``
/// events and rendering output ``ProcessedImage`` in a image view.
public struct AssSubtitles: PlatformViewRepresentable {
    private let renderer: AssSubtitlesRenderer
    private let scale: CGFloat

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
    public init(renderer: AssSubtitlesRenderer) {
        self.renderer = renderer
        self.scale = 2.0
    }

    public func makeNSView(context: Context) -> AssSubtitlesView {
        AssSubtitlesView(renderer: renderer)
    }

    public func updateNSView(_ nsView: AssSubtitlesView, context: Context) {
        nsView.renderer.reloadFrame()
    }
    #endif
}

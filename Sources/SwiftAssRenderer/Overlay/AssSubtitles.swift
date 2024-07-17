import SwiftUI

/// SwiftUI `View` capable or drawing rendered image bitmaps to the screen, by subscribing to ``AssSubtitlesRenderer``
/// events and rendering output ``ProcessedImage`` in a image view.
public struct AssSubtitles: PlatformViewRepresentable {
    private(set) var imageCallback: AssSubtitlesImageCallback?
    let renderer: AssSubtitlesRenderer
    let scale: CGFloat

    #if canImport(UIKit)
    public init(renderer: AssSubtitlesRenderer, scale: CGFloat = UITraitCollection.current.displayScale) {
        self.renderer = renderer
        self.scale = scale
    }

    public func makeUIView(context: Context) -> AssSubtitlesView {
        AssSubtitlesView(renderer: renderer, scale: scale)
            .onImageChanged(imageCallback)
    }

    public func updateUIView(_ uiView: AssSubtitlesView, context: Context) {
        uiView.onImageChanged(imageCallback)
        uiView.renderer.reloadFrame()
    }
    #elseif canImport(AppKit)
    public init(renderer: AssSubtitlesRenderer, scale: CGFloat = 2.0) {
        self.renderer = renderer
        self.scale = scale
    }

    public func makeNSView(context: Context) -> AssSubtitlesView {
        AssSubtitlesView(renderer: renderer, scale: scale)
            .onImageChanged(imageCallback)
    }

    public func updateNSView(_ nsView: AssSubtitlesView, context: Context) {
        nsView.onImageChanged(imageCallback)
        nsView.renderer.reloadFrame()
    }
    #endif
}

public extension AssSubtitles {
    /// Assign a callback to be called when subtitle image is set, changed or removed.
    ///
    /// - Parameters:
    ///   - callback: Callback to call.
    ///
    /// Calling this multiple times will override previous callbacks.
    func onImageChanged(_ callback: AssSubtitlesImageCallback?) -> Self {
        var view = self
        view.imageCallback = callback

        return view
    }
}

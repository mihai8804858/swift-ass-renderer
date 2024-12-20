#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif
import SwiftUI
import Combine

/// Callback called when image view is being updated (subtitle image set, updated or removed).
/// The `dialogues` argument is not sanitized and might include ASS formatting tags.
public typealias AssSubtitlesImageCallback = (
    _ subtitlesView: AssSubtitlesView,
    _ subtitlesImageView: PlatformImageView,
    _ processedImage: ProcessedImage?,
    _ dialogues: [String]
) -> Void

/// `UIView` /  `NSView` capable or drawing rendered image bitmaps to the screen,
/// by subscribing to ``AssSubtitlesRenderer``  events and rendering output ``ProcessedImage`` in a image view.
public final class AssSubtitlesView: PlatformView {
    public let renderer: AssSubtitlesRenderer

    private let canvasScale: CGFloat
    private let imageView = PlatformImageView()
    private var lastRenderBounds = CGRect.zero
    private var cancellables = Set<AnyCancellable>()
    private var imageCallback: AssSubtitlesImageCallback?

    public required init?(coder: NSCoder) {
        fatalError("init(coder:) not supported")
    }

    #if canImport(UIKit)
    public init(renderer: AssSubtitlesRenderer, scale: CGFloat = UITraitCollection.current.displayScale) {
        self.renderer = renderer
        self.canvasScale = scale
        super.init(frame: .zero)
        configure()
    }

    public override func layoutSubviews() {
        super.layoutSubviews()

        resizeCanvas()
    }
    #elseif canImport(AppKit)
    public init(renderer: AssSubtitlesRenderer, scale: CGFloat = 2.0) {
        self.renderer = renderer
        self.canvasScale = scale
        super.init(frame: .zero)
        configure()
    }

    public override func layout() {
        super.layout()

        resizeCanvas()
    }

    public override func hitTest(_ point: NSPoint) -> NSView? {
        return nil
    }
    #endif

    @MainActor
    private func resizeCanvas() {
        resizeImageAtLayout()
        renderer.setCanvasSize(bounds.size, scale: canvasScale)
    }
}

public extension AssSubtitlesView {
    /// Assign a callback to be called when subtitle image is set, changed or removed.
    ///
    /// - Parameters:
    ///   - callback: Callback to call.
    ///
    /// Calling this multiple times will override previous callbacks.
    @MainActor
    @discardableResult
    func onImageChanged(_ callback: AssSubtitlesImageCallback?) -> Self {
        imageCallback = callback
        return self
    }
}

private extension AssSubtitlesView {
    @MainActor
    func configure() {
        setupView()
        subscribeToEvents()
    }

    @MainActor
    func setupView() {
        addSubview(imageView)
        #if canImport(UIKit)
        backgroundColor = .clear
        isUserInteractionEnabled = false
        #elseif canImport(AppKit)
        wantsLayer = true
        layer?.backgroundColor = NSColor.clear.cgColor
        #endif
    }

    @MainActor
    func subscribeToEvents() {
        renderer
            .framesPublisher()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.handleFrameChanged($0) }
            .store(in: &cancellables)
    }

    @MainActor
    func handleFrameChanged(_ image: ProcessedImage?) {
        if let image {
            resizeImageView(for: image)
            #if canImport(UIKit)
            imageView.image = PlatformImage(cgImage: image.image)
            #elseif canImport(AppKit)
            imageView.image = PlatformImage(cgImage: image.image, size: image.imageRect.size)
            #endif
            imageView.isHidden = false
        } else {
            imageView.isHidden = true
            imageView.image = nil
        }
        if let imageCallback {
            let dialogues = renderer.dialogues(at: renderer.currentOffset)
            imageCallback(self, imageView, image, dialogues)
        }
    }

    @MainActor
    func resizeImageView(for image: ProcessedImage) {
        lastRenderBounds = bounds
        imageView.frame = imageFrame(for: image.imageRect)
    }

    @MainActor
    func resizeImageAtLayout() {
        if lastRenderBounds.isEmpty || bounds.isEmpty || imageView.image == nil { return }
        let ratioX = 1 / (lastRenderBounds.width / bounds.width)
        let ratioY = 1 / (lastRenderBounds.height / bounds.height)
        let newOrigin = CGPoint(x: imageView.frame.origin.x * ratioX, y: imageView.frame.origin.y * ratioY)
        let newSize = CGSize(width: imageView.frame.width * ratioX, height: imageView.frame.height * ratioY)
        let newFrame = CGRect(origin: newOrigin, size: newSize).integral
        CATransaction.begin()
        imageView.frame = newFrame
        CATransaction.commit()
    }

    @MainActor
    func imageFrame(for rect: CGRect) -> CGRect {
        #if canImport(UIKit)
        rect
        #elseif canImport(AppKit)
        // macOS has the origin on bottom left corner
        rect.flippingY(for: bounds.height)
        #endif
    }
}

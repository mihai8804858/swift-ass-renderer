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

    private func resizeCanvas() {
        resizeImageAtLayout()
        renderer.setCanvasSize(bounds.size, scale: canvasScale)
    }
}

public extension AssSubtitlesView {
    @discardableResult
    func onImageChanged(_ callback: AssSubtitlesImageCallback?) -> Self {
        imageCallback = callback
        return self
    }
}

private extension AssSubtitlesView {
    func configure() {
        setupView()
        subscribeToEvents()
    }

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

    func subscribeToEvents() {
        renderer
            .framesPublisher()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.handleFrameChanged($0) }
            .store(in: &cancellables)
    }

    func handleFrameChanged(_ image: ProcessedImage?) {
        UI { [weak self] in
            guard let self else { return }
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
    }

    func resizeImageView(for image: ProcessedImage) {
        UI { [weak self] in
            guard let self else { return }
            lastRenderBounds = bounds
            imageView.frame = imageFrame(for: image.imageRect)
        }
    }

    func resizeImageAtLayout() {
        UI { [weak self] in
            guard let self else { return }
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
    }

    func imageFrame(for rect: CGRect) -> CGRect {
        #if canImport(UIKit)
        rect
        #elseif canImport(AppKit)
        // macOS has the origin on bottom left corner
        rect.flippingY(for: bounds.height)
        #endif
    }
}

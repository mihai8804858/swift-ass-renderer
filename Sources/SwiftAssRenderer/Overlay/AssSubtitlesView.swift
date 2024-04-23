#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif
import SwiftUI
import Combine

/// `UIView` /  `NSView` capable or drawing rendered image bitmaps to the screen,
/// by subscribing to ``AssSubtitlesRenderer``  events and rendering output ``ProcessedImage`` in a image view.
public final class AssSubtitlesView: PlatformView {
    public let renderer: AssSubtitlesRenderer

    private let canvasScale: CGFloat
    private let imageView = PlatformImageView()
    private var lastRenderBounds = CGRect.zero
    private var cancellables = Set<AnyCancellable>()

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
    }

    func resizeImageView(for image: ProcessedImage) {
        lastRenderBounds = bounds
        imageView.frame = imageFrame(for: image.imageRect)
    }

    func resizeImageAtLayout() {
        if lastRenderBounds.isEmpty || bounds.isEmpty || imageView.image == nil { return }
        let ratioX = 1 / (lastRenderBounds.width / bounds.width)
        let ratioY = 1 / (lastRenderBounds.height / bounds.height)
        let newOrigin = CGPoint(x: imageView.frame.origin.x * ratioX, y: imageView.frame.origin.y * ratioY)
        let newSize = CGSize(width: imageView.frame.width * ratioX, height: imageView.frame.height * ratioY)
        let newFrame = CGRect(origin: newOrigin, size: newSize)
        CATransaction.begin()
        imageView.frame = newFrame
        CATransaction.commit()
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

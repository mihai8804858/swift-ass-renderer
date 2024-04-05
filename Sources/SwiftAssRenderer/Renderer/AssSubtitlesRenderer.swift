import Combine
import Foundation
import SwiftLibass
import CombineSchedulers

public typealias LibrarySetup = (_ library: OpaquePointer) -> Void
public typealias RendererSetup = (_ library: OpaquePointer, _ renderer: OpaquePointer) -> Void

/// ASS/SSA subtitles renderer. Manages the current ASS track, 
/// current time offset and current visible frame (``ProcessedImage``).
public final class AssSubtitlesRenderer {
    private let workQueue: DispatchQueueType
    private let scheduler: AnySchedulerOf<DispatchQueue>
    private let wrapper: LibraryWrapperType.Type
    private let fontConfig: FontConfigType
    private let pipeline: ImagePipelineType
    private let logger: LoggerType
    private let librarySetup: LibrarySetup?
    private let rendererSetup: RendererSetup?

    private var library: OpaquePointer?
    private var renderer: OpaquePointer?

    private var canvasSize: CGSize = .zero
    private var canvasScale: CGFloat = 1.0

    private var currentTrack: ASS_Track?
    private var currentOffset: TimeInterval = 0
    private var currentFrame = CurrentValueSubject<ProcessedImage?, Never>(nil)

    /// - Parameters:
    ///   - fontConfig: Fonts configuration. Defines where the fonts and fonts cache is located, 
    ///   fallbacks for missing fonts and the default ``FontProvider`` to use.
    ///   - pipeline: Image pipeline to use for precessing ``ASS_Image`` into ``ProcessedImage``.
    ///   - logOutput: Log output. 
    ///   Defaults to logging to console with `.default` level in DEBUG and `.fatal` in RELEASE.
    ///   - librarySetup: Custom actions to run when initializing the ``ASS_Library``.
    ///   - rendererSetup: Custom actions to run when initializing the ``ASS_Renderer``.
    public convenience init(
        fontConfig: FontConfig,
        pipeline: ImagePipelineType = BlendImagePipeline(),
        logOutput: LogOutput? = nil,
        librarySetup: LibrarySetup? = nil,
        rendererSetup: RendererSetup? = nil
    ) {
        self.init(
            workQueue: DispatchQueue(label: "com.swift-ass-renderer.work", qos: .userInteractive),
            scheduler: .main,
            wrapper: LibraryWrapper.self,
            fontConfig: fontConfig,
            pipeline: pipeline,
            logger: Logger(output: logOutput),
            librarySetup: librarySetup,
            rendererSetup: rendererSetup
        )
    }

    init(
        workQueue: DispatchQueueType,
        scheduler: AnySchedulerOf<DispatchQueue>,
        wrapper: LibraryWrapperType.Type,
        fontConfig: FontConfigType,
        pipeline: ImagePipelineType,
        logger: LoggerType,
        librarySetup: LibrarySetup?,
        rendererSetup: RendererSetup?
    ) {
        self.workQueue = workQueue
        self.scheduler = scheduler
        self.wrapper = wrapper
        self.fontConfig = fontConfig
        self.pipeline = pipeline
        self.logger = logger
        self.librarySetup = librarySetup
        self.rendererSetup = rendererSetup
        configure()
    }

    deinit {
        freeTrack()
        renderer.flatMap(wrapper.rendererDone)
        library.flatMap(wrapper.libraryDone)
    }

    /// Parse and load ASS/SSA subtitle track in memory.
    ///
    /// - Parameters:
    ///   - content: Raw ASS/SSA subtitle contents.
    ///
    /// Always call this method before starting to update the time offset.
    public func loadTrack(content: String) {
        guard let library else {
            return logger.log(message: LogMessage(
                message: "Track cannot be loaded since library has not been initialized",
                level: .verbose
            ))
        }
        workQueue.executeAsync { [weak self] in
            guard let self else { return }
            freeTrack()
            currentTrack = wrapper.readTrack(library, content: content)
        }
    }

    /// Removes current track and resets the time offset and current visible frame.
    public func freeTrack() {
        currentTrack = nil
        currentFrame.value = nil
        currentOffset = 0
    }

    /// Set subtitles canvas size and scale.
    ///
    /// - Parameters:
    ///   - size: Canvas size. Should match the video canvas for proper subtitle positioning.
    ///   - scale: Screen scale. Bigger scale results in sharper images, but lower performance.
    ///
    /// Always call this method before starting to update the time offset.
    /// When using the renderer with ``AssSubtitles`` / ``AssSubtitlesView``, you don't have to call this method.
    public func setCanvasSize(_ size: CGSize, scale: CGFloat) {
        canvasSize = size
        canvasScale = scale
        guard let renderer else {
            return logger.log(message: LogMessage(
                message: "Can't set canvas size since renderer has not been initialized",
                level: .verbose
            ))
        }
        wrapper.setRendererSize(renderer, size: size * scale)
    }

    /// Set current visible subtitle offset.
    ///
    /// - Parameters:
    ///   - offset: Time interval (in seconds) from where to render the current visible subtitle.
    ///
    /// This method should be called periodically to update the current visible subtitle. 
    /// If called too often, it might result in lower performance.
    public func setTimeOffset(_ offset: TimeInterval) {
        currentOffset = offset
        loadFrame(offset: offset)
    }

    /// Publisher where the rendered images to be drawn are being published.
    ///
    /// - Returns: A Combine publisher where ``ProcessedImage`` that have to be drawn on the canvas are being published.
    ///
    /// When using the renderer with ``AssSubtitles`` / ``AssSubtitlesView``,
    /// you don't have to subscribe to this publisher and render the images.
    public func framesPublisher() -> AnyPublisher<ProcessedImage?, Never> {
        currentFrame
            .share()
            .removeDuplicates { $0 == nil && $1 == nil }
            .receive(on: scheduler)
            .eraseToAnyPublisher()
    }

    /// Forces the current visible subtitle to be reloaded and redrawn.
    ///
    /// When using the renderer with ``AssSubtitles`` / ``AssSubtitlesView``, you don't have to call this method.
    public func reloadFrame() {
        loadFrame(offset: currentOffset)
    }
}

private extension AssSubtitlesRenderer {
    enum FrameResult {
        case loaded(ProcessedImage)
        case unchanged
        case none
    }

    func loadFrame(offset: TimeInterval) {
        workQueue.executeAsync { [weak self] in
            guard let self else { return }
            switch frame(at: offset) {
            case .unchanged: break
            case .none: currentFrame.value = nil
            case .loaded(let image): currentFrame.value = image
            }
        }
    }

    func frame(at offset: TimeInterval) -> FrameResult {
        guard let renderer else {
            logger.log(message: LogMessage(
                message: "Can't render frame since renderer has not been initialized",
                level: .verbose
            ))
            return .none
        }
        guard var currentTrack else {
            logger.log(message: LogMessage(
                message: "Can't render frame since track has not been loaded",
                level: .verbose
            ))
            return .none
        }
        guard let result = wrapper.renderImage(renderer, track: &currentTrack, at: offset) else {
            return .none
        }
        guard result.changed else { return .unchanged }
        guard let processedImage = pipeline.process(image: result.image) else {
            return .none
        }
        let imageRect = (processedImage.imageRect / canvasScale).rounded()

        return .loaded(ProcessedImage(image: processedImage.image, imageRect: imageRect))
    }
}

private extension AssSubtitlesRenderer {
    func configure() {
        workQueue.executeAsync { [weak self] in
            guard let self else { return }
            configureLibrary()
            configureFonts()
            setCanvasSize(canvasSize, scale: canvasScale)
        }
    }

    func configureLibrary() {
        library = wrapper.libraryInit()
        guard let library else {
            return logger.log(message: LogMessage(
                message: "Library could not be initialized",
                level: .fatal
            ))
        }
        logger.configureLibrary(wrapper, library: library)
        renderer = wrapper.rendererInit(library)
        guard let renderer else {
            return logger.log(message: LogMessage(
                message: "Renderer could not be initialized",
                level: .fatal
            ))
        }
        librarySetup?(library)
        rendererSetup?(library, renderer)
    }

    func configureFonts() {
        do {
            guard let library, let renderer else {
                return logger.log(message: LogMessage(
                    message: "Library and renderer have not been initialized before setting fonts",
                    level: .fatal
                ))
            }
            try fontConfig.configure(library: library, renderer: renderer)
        } catch {
            logger.log(message: LogMessage(message: "Failed settings fonts - \(error)", level: .fatal))
        }
    }
}

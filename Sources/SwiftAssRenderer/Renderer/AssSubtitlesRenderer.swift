import Combine
import Foundation
import SwiftLibass
import CombineSchedulers

public typealias LibrarySetup = (_ library: OpaquePointer) -> Void
public typealias RendererSetup = (_ library: OpaquePointer, _ renderer: OpaquePointer) -> Void

/// ASS/SSA subtitles renderer. Manages the current ASS track, 
/// current time offset and current visible frame (``ProcessedImage``).
public final class AssSubtitlesRenderer {
    public enum FrameRenderResult {
        case loaded(ProcessedImage)
        case unchanged
        case none
    }

    private let workQueue: DispatchQueueType
    private let scheduler: AnySchedulerOf<DispatchQueue>
    private let wrapper: LibraryWrapperType.Type
    private let fontConfig: FontConfigType
    private let pipeline: ImagePipelineType
    private let logger: LoggerType
    private let contentsLoader: ContentsLoaderType
    private let librarySetup: LibrarySetup?
    private let rendererSetup: RendererSetup?

    private var library: OpaquePointer?
    private var renderer: OpaquePointer?

    private var canvasSize: CGSize = .zero
    private var canvasScale: CGFloat = 1.0
    private var cancellables: Set<AnyCancellable> = []

    private var currentTrack: ASS_Track?
    private var currentOffset: TimeInterval = 0
    private var currentFrame = CurrentValueSubject<ProcessedImage?, Never>(nil)

    /// - Parameters:
    ///   - fontConfig: Fonts configuration. Defines where the fonts and fonts cache is located, 
    ///   fallbacks for missing fonts and the default ``FontProvider`` to use.
    ///   - pipeline: Image pipeline to use for precessing `ASS_Image` into ``ProcessedImage``.
    ///   - logOutput: Log output. 
    ///   Defaults to logging to console with `.default` level in DEBUG and `.fatal` in RELEASE.
    ///   - librarySetup: Custom actions to run when initializing the `ASS_Library`.
    ///   - rendererSetup: Custom actions to run when initializing the `ASS_Renderer`.
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
            contentsLoader: ContentsLoader(),
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
        contentsLoader: ContentsLoaderType,
        librarySetup: LibrarySetup?,
        rendererSetup: RendererSetup?
    ) {
        self.workQueue = workQueue
        self.scheduler = scheduler
        self.wrapper = wrapper
        self.fontConfig = fontConfig
        self.pipeline = pipeline
        self.logger = logger
        self.contentsLoader = contentsLoader
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
        workQueue.executeAsync { [weak self] in
            guard let self else { return }
            guard let library else {
                return logger.log(message: LogMessage(
                    message: "Track cannot be loaded since library has not been initialized",
                    level: .verbose
                ))
            }
            freeTrack()
            currentTrack = wrapper.readTrack(library, content: content)
        }
    }

    /// Load a new track from provided content and restore the time offset to last known position.
    ///
    /// - Parameters:
    ///   - content: Raw ASS/SSA subtitle contents.
    public func reloadTrack(content: String) {
        let restoreOffset = currentOffset
        freeTrack()
        loadTrack(content: content)
        loadFrame(offset: restoreOffset)
    }

    /// Parse and load ASS/SSA subtitle track in memory.
    ///
    /// - Parameters:
    ///   - url: File or remote URL to subtitle contents .
    ///
    /// Always call this method before starting to update the time offset.
    public func loadTrack(url: URL) {
        freeTrack()
        loadContents(from: url) { [weak self] contents in
            guard let self else { return }
            loadTrack(content: contents)
        }
    }

    /// Load a new track from provided URL and restore the time offset to last known position.
    ///
    /// - Parameters:
    ///   - url: File or remote URL to subtitle contents .
    public func reloadTrack(url: URL) {
        let restoreOffset = currentOffset
        freeTrack()
        loadContents(from: url) { [weak self] contents in
            guard let self else { return }
            loadTrack(content: contents)
            loadFrame(offset: restoreOffset)
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
        if canvasSize == size && canvasScale == scale { return }
        canvasSize = size
        canvasScale = scale
        workQueue.executeAsync { [weak self] in
            guard let self else { return }
            guard let renderer else {
                return logger.log(message: LogMessage(
                    message: "Can't set canvas size since renderer has not been initialized",
                    level: .verbose
                ))
            }
            wrapper.setRendererSize(renderer, size: size * scale)
            reloadFrame()
        }
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

    /// Load frame (if any) at the given offset.
    ///
    /// - Parameters:
    ///   - offset: Time interval (in seconds) where to load the subtitle frame.
    ///   - completion: Completion handler.
    public func loadFrame(offset: TimeInterval, completion: @escaping (ProcessedImage?) -> Void = { _ in }) {
        workQueue.executeAsync { [weak self] in
            defer { completion(self?.currentFrame.value) }
            guard let self, var currentTrack else { return }
            setCurrentFrame(from: frame(at: offset, in: &currentTrack))
        }
    }

    /// Load frame synchronously at the given offset.
    ///
    /// - Parameters:
    ///   - offset: Time interval (in seconds) where to load the subtitle frame.
    ///
    /// - Returns: ``FrameRenderResult`` relative to last renderer frame.
    public func loadFrameSync(offset: TimeInterval) -> FrameRenderResult {
        guard var currentTrack else { return .none }
        let result = frame(at: offset, in: &currentTrack)
        setCurrentFrame(from: result)

        return result
    }
}

private extension AssSubtitlesRenderer {
    private func setCurrentFrame(from result: FrameRenderResult) {
        switch result {
        case .unchanged: break
        case .none: currentFrame.value = nil
        case .loaded(let image): currentFrame.value = image
        }
    }

    func frame(at offset: TimeInterval, in track: inout ASS_Track) -> FrameRenderResult {
        guard let renderer else {
            logger.log(message: LogMessage(
                message: "Can't render frame since renderer has not been initialized",
                level: .verbose
            ))
            return .none
        }
        guard let result = wrapper.renderImage(renderer, track: &track, at: offset) else {
            return .none
        }
        guard result.changed else { return .unchanged }
        let images = linkedImages(from: result.image)
        let boundingRect = imagesBoundingRect(images: images)
        guard let processedImage = pipeline.process(images: images, boundingRect: boundingRect) else {
            return .none
        }
        let imageRect = (processedImage.imageRect / canvasScale).integral

        return .loaded(ProcessedImage(image: processedImage.image, imageRect: imageRect))
    }

    func loadContents(from url: URL, completion: @escaping (String) -> Void) {
        contentsLoader
            .loadContents(from: url)
            .sink { [weak self] completion in
                guard let self, case .failure(let error) = completion else { return }
                logger.log(
                    message: LogMessage(message: "Could not load subtitle contents: \(error)",
                    level: .fatal
                ))
            } receiveValue: { contents in
                guard let contents else { return }
                completion(contents)
            }.store(in: &cancellables)
    }
}

private extension AssSubtitlesRenderer {
    func configure() {
        workQueue.executeAsync { [weak self] in
            guard let self else { return }
            configureLibrary()
            configureFonts()
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
            logger.log(message: LogMessage(message: "Failed setting fonts - \(error)", level: .fatal))
        }
    }
}

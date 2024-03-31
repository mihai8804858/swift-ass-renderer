import Combine
import Foundation
import SwiftLibass
import CombineSchedulers

public final class AssSubtitlesRenderer {
    private let queue: DispatchQueueType
    private let scheduler: AnySchedulerOf<DispatchQueue>
    private let wrapper: LibraryWrapperType.Type
    private let fontConfig: FontConfigType
    private let pipeline: ImagePipelineType
    private let logger: LoggerType

    private var library: OpaquePointer?
    private var renderer: OpaquePointer?

    private var canvasSize: CGSize = .zero
    private var canvasScale: CGFloat = 1.0

    private var currentTrack: ASS_Track?
    private var currentOffset: TimeInterval = 0
    private var currentFrame = CurrentValueSubject<ProcessedImage?, Never>(nil)

    public convenience init(fontConfig: FontConfig, logLevel: LogLevel? = nil) {
        self.init(
            queue: DispatchQueue(label: "com.swift-ass-renderer.work", qos: .userInteractive),
            scheduler: .main,
            wrapper: LibraryWrapper.self,
            fontConfig: fontConfig,
            pipeline: ImagePipeline(),
            logger: Logger(level: logLevel, prefix: "swift-ass")
        )
    }

    init(
        queue: DispatchQueueType,
        scheduler: AnySchedulerOf<DispatchQueue>,
        wrapper: LibraryWrapperType.Type,
        fontConfig: FontConfigType,
        pipeline: ImagePipelineType,
        logger: LoggerType
    ) {
        self.queue = queue
        self.scheduler = scheduler
        self.wrapper = wrapper
        self.fontConfig = fontConfig
        self.pipeline = pipeline
        self.logger = logger
        configure()
    }

    deinit {
        freeTrack()
        renderer.flatMap(wrapper.rendererDone)
        library.flatMap(wrapper.libraryDone)
    }

    public func loadTrack(content: String) {
        guard let library else {
            return logger.log(
                message: "Track cannot be loaded since library has not been initialized",
                messageLevel: .verbose
            )
        }
        freeTrack()
        currentTrack = wrapper.readTrack(library, content: content)
    }

    public func freeTrack() {
        guard var track = currentTrack else { return }
        wrapper.freeTrack(&track)
        currentTrack = nil
        currentFrame.value = nil
        currentOffset = 0
    }

    public func setTimeOffset(_ offset: TimeInterval) {
        currentOffset = offset
        loadFrame(offset: offset)
    }
}

extension AssSubtitlesRenderer {
    func setCanvasSize(_ size: CGSize, scale: CGFloat) {
        canvasSize = size
        canvasScale = scale
        guard let renderer else {
            return logger.log(
                message: "Can't set canvas size since renderer has not been initialized",
                messageLevel: .verbose
            )
        }
        wrapper.setRendererSize(renderer, size: size * scale)
    }

    func framesPublisher() -> AnyPublisher<ProcessedImage?, Never> {
        currentFrame
            .share()
            .removeDuplicates { $0 == nil && $1 == nil }
            .receive(on: scheduler)
            .eraseToAnyPublisher()
    }

    func reloadFrame() {
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
        queue.executeAsync { [weak self] in
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
            logger.log(message: "Can't render frame since renderer has not been initialized", messageLevel: .verbose)
            return .none
        }
        guard var currentTrack else {
            logger.log(message: "Can't render frame since track has not been loaded", messageLevel: .verbose)
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
        configureLibrary()
        configureFonts()
        setCanvasSize(canvasSize, scale: canvasScale)
    }

    func configureLibrary() {
        library = wrapper.libraryInit()
        guard let library else {
            return logger.log(
                message: "Library could not be initialized",
                messageLevel: .fatal
            )
        }
        logger.configureLibrary(wrapper, library: library)
        renderer = wrapper.rendererInit(library)
    }

    func configureFonts() {
        do {
            guard let library, let renderer else {
                return logger.log(
                    message: "Library and renderer have not been initialized before setting fonts",
                    messageLevel: .fatal
                )
            }
            try fontConfig.configure(library: library, renderer: renderer)
        } catch {
            logger.log(message: "Failed settings fonts - \(error)", messageLevel: .fatal)
        }
    }
}

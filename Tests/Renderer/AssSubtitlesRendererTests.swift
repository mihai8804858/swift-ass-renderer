import XCTest
import Combine
import CombineSchedulers
import SwiftLibass
import SwiftAssBlend
@testable import SwiftAssRenderer

final class AssSubtitlesRendererTests: XCTestCase {
    private var mockQueue: MockDispatchQueue!
    private var mockLibraryWrapper: MockLibraryWrapper.Type!
    private var mockFontConfig: MockFontConfig!
    private var mockImagePipeline: MockImagePipeline!
    private var mockLogger: MockLogger!
    private var mockContentsLoader: MockContentsLoader!
    private var librarySetupFunc: FuncCheck<OpaquePointer>!
    private var rendererSetupFunc: FuncCheck<(OpaquePointer, OpaquePointer)>!
    private var cancellables = Set<AnyCancellable>()

    override func setUp() {
        super.setUp()

        mockQueue = MockDispatchQueue()
        mockLibraryWrapper = MockLibraryWrapper.self
        mockFontConfig = MockFontConfig()
        mockImagePipeline = MockImagePipeline()
        mockLogger = MockLogger()
        mockContentsLoader = MockContentsLoader()
        librarySetupFunc = FuncCheck<OpaquePointer>()
        rendererSetupFunc = FuncCheck<(OpaquePointer, OpaquePointer)>()
        cancellables.removeAll()
    }

    func createRenderer() -> AssSubtitlesRenderer {
        AssSubtitlesRenderer(
            workQueue: mockQueue,
            scheduler: .immediate,
            wrapper: mockLibraryWrapper,
            fontConfig: mockFontConfig,
            pipeline: mockImagePipeline,
            logger: mockLogger,
            contentsLoader: mockContentsLoader,
            librarySetup: { self.librarySetupFunc.call($0) },
            rendererSetup: { self.rendererSetupFunc.call(($0, $1)) }
        )
    }

    func test_init_shouldInitLibrary() throws {
        // WHEN
        _ = createRenderer()

        // THEN
        XCTAssert(mockLibraryWrapper.libraryInitFunc.wasCalled)
    }

    func test_init_shouldInitRenderer() throws {
        // GIVEN
        let library = OpaquePointer(bitPattern: 1)!
        mockLibraryWrapper.libraryInitStub = library

        // WHEN
        _ = createRenderer()

        // THEN
        XCTAssert(mockLibraryWrapper.rendererInitFunc.wasCalled(with: library))
    }

    func test_init_shouldCallLibrarySetup() throws {
        // GIVEN
        let library = OpaquePointer(bitPattern: 1)!
        let renderer = OpaquePointer(bitPattern: 2)!
        mockLibraryWrapper.libraryInitStub = library
        mockLibraryWrapper.rendererInitStub = renderer

        // WHEN
        _ = createRenderer()

        // THEN
        XCTAssert(librarySetupFunc.wasCalled(with: library))
    }

    func test_init_shouldCallRendererSetup() throws {
        // GIVEN
        let library = OpaquePointer(bitPattern: 1)!
        let renderer = OpaquePointer(bitPattern: 2)!
        mockLibraryWrapper.libraryInitStub = library
        mockLibraryWrapper.rendererInitStub = renderer

        // WHEN
        _ = createRenderer()

        // THEN
        let argument = try XCTUnwrap(rendererSetupFunc.argument)
        XCTAssert(rendererSetupFunc.wasCalled)
        XCTAssert(argument == (library, renderer))
    }

    func test_init_shouldConfigureLoggerLibrary() throws {
        // GIVEN
        let library = OpaquePointer(bitPattern: 1)!
        mockLibraryWrapper.libraryInitStub = library

        // WHEN
        _ = createRenderer()

        // THEN
        XCTAssert(mockLogger.configureLibraryFunc.wasCalled)
    }

    func test_init_shouldConfigureFonts() throws {
        // GIVEN
        let library = OpaquePointer(bitPattern: 1)!
        let renderer = OpaquePointer(bitPattern: 2)!
        mockLibraryWrapper.libraryInitStub = library
        mockLibraryWrapper.rendererInitStub = renderer

        // WHEN
        _ = createRenderer()

        // THEN
        XCTAssert(mockFontConfig.configureFunc.wasCalled)
        let argument = try XCTUnwrap(mockFontConfig.configureFunc.argument)
        XCTAssert(argument == (library, renderer))
    }

    func test_loadTrackContent_shouldReadTrack() throws {
        // GIVEN
        let library = OpaquePointer(bitPattern: 1)!
        let renderer = OpaquePointer(bitPattern: 2)!
        let content = "<CONTENT>"
        mockLibraryWrapper.libraryInitStub = library
        mockLibraryWrapper.rendererInitStub = renderer

        // WHEN
        let subRenderer = createRenderer()
        subRenderer.loadTrack(content: content)

        // THEN
        XCTAssert(mockLibraryWrapper.readTrackFunc.wasCalled)
        let argument = try XCTUnwrap(mockLibraryWrapper.readTrackFunc.argument)
        XCTAssert(argument == (library, content))
    }

    func test_reloadTrackContent_shouldReadTrackAndLoadLastKnownOffset() throws {
        // GIVEN
        let library = OpaquePointer(bitPattern: 1)!
        let renderer = OpaquePointer(bitPattern: 2)!
        let content = "<CONTENT>"
        let newContent = "<NEW_CONTENT>"
        let offset = 10.0
        mockLibraryWrapper.libraryInitStub = library
        mockLibraryWrapper.rendererInitStub = renderer

        let subRenderer = createRenderer()
        subRenderer.loadTrack(content: content)
        subRenderer.setTimeOffset(offset)

        mockLibraryWrapper.readTrackFunc.reset()
        mockLibraryWrapper.renderImageFunc.reset()

        // WHEN
        subRenderer.reloadTrack(content: newContent)

        // THEN
        XCTAssert(mockLibraryWrapper.readTrackFunc.wasCalled)
        XCTAssert(mockLibraryWrapper.renderImageFunc.wasCalled)
        let contentArgument = try XCTUnwrap(mockLibraryWrapper.readTrackFunc.argument)
        let offsetArgument = try XCTUnwrap(mockLibraryWrapper.renderImageFunc.argument)
        XCTAssert(contentArgument.1 == newContent)
        XCTAssert(offsetArgument.2 == offset)
    }

    func test_loadTrackURL_shouldReadTrack() throws {
        // GIVEN
        let library = OpaquePointer(bitPattern: 1)!
        let renderer = OpaquePointer(bitPattern: 2)!
        let content = "<CONTENT>"
        let url = URL(string: "file://path/to/subtitle.ass")!
        mockLibraryWrapper.libraryInitStub = library
        mockLibraryWrapper.rendererInitStub = renderer
        mockContentsLoader.loadContentsStub = Just(content)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()

        // WHEN
        let subRenderer = createRenderer()
        subRenderer.loadTrack(url: url)

        // THEN
        XCTAssert(mockLibraryWrapper.readTrackFunc.wasCalled)
        let argument = try XCTUnwrap(mockLibraryWrapper.readTrackFunc.argument)
        XCTAssert(argument == (library, content))
    }

    func test_reloadTrackURL_shouldReadTrackAndLoadLastKnownOffset() throws {
        // GIVEN
        let library = OpaquePointer(bitPattern: 1)!
        let renderer = OpaquePointer(bitPattern: 2)!
        let content = "<CONTENT>"
        let url = URL(string: "file://path/to/subtitle.ass")!
        let newContent = "<NEW_CONTENT>"
        let newURL = URL(string: "file://path/to/new/subtitle.ass")!
        let offset = 10.0
        mockLibraryWrapper.libraryInitStub = library
        mockLibraryWrapper.rendererInitStub = renderer
        mockContentsLoader.loadContentsStub = Just(content)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()

        let subRenderer = createRenderer()
        subRenderer.loadTrack(url: url)
        subRenderer.setTimeOffset(offset)

        mockLibraryWrapper.readTrackFunc.reset()
        mockLibraryWrapper.renderImageFunc.reset()

        // WHEN
        mockContentsLoader.loadContentsStub = Just(newContent)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
        subRenderer.reloadTrack(url: newURL)

        // THEN
        XCTAssert(mockLibraryWrapper.readTrackFunc.wasCalled)
        XCTAssert(mockLibraryWrapper.renderImageFunc.wasCalled)
        XCTAssert(mockContentsLoader.loadContentsFunc.wasCalled)
        let contentArgument = try XCTUnwrap(mockLibraryWrapper.readTrackFunc.argument)
        let offsetArgument = try XCTUnwrap(mockLibraryWrapper.renderImageFunc.argument)
        let urlArgument = try XCTUnwrap(mockContentsLoader.loadContentsFunc.argument)
        XCTAssert(contentArgument.1 == newContent)
        XCTAssert(offsetArgument.2 == offset)
        XCTAssert(urlArgument == newURL)
    }

    func test_deinit_shouldCallRendererDone() throws {
        // GIVEN
        let library = OpaquePointer(bitPattern: 1)!
        let renderer = OpaquePointer(bitPattern: 2)!
        let content = "<CONTENT>"
        mockLibraryWrapper.libraryInitStub = library
        mockLibraryWrapper.rendererInitStub = renderer
        mockLibraryWrapper.readTrackStub = ASS_Track()

        // WHEN
        var subRenderer: AssSubtitlesRenderer? = createRenderer()
        subRenderer?.loadTrack(content: content)
        subRenderer = nil

        // THEN
        XCTAssert(mockLibraryWrapper.rendererDoneFunc.wasCalled)
    }

    func test_deinit_shouldCallLibraryDone() throws {
        // GIVEN
        let library = OpaquePointer(bitPattern: 1)!
        let renderer = OpaquePointer(bitPattern: 2)!
        let content = "<CONTENT>"
        mockLibraryWrapper.libraryInitStub = library
        mockLibraryWrapper.rendererInitStub = renderer
        mockLibraryWrapper.readTrackStub = ASS_Track()

        // WHEN
        var subRenderer: AssSubtitlesRenderer? = createRenderer()
        subRenderer?.loadTrack(content: content)
        subRenderer = nil

        // THEN
        XCTAssert(mockLibraryWrapper.libraryDoneFunc.wasCalled)
    }

    func test_setCanvasSize_whenSizeOrScaleAreDifferent_shouldSetRendererSize() throws {
        // GIVEN
        let library = OpaquePointer(bitPattern: 1)!
        let renderer = OpaquePointer(bitPattern: 2)!
        let content = "<CONTENT>"
        let size = CGSize(width: 1920, height: 1080)
        let scale = 3.0
        mockLibraryWrapper.libraryInitStub = library
        mockLibraryWrapper.rendererInitStub = renderer
        mockLibraryWrapper.readTrackStub = ASS_Track()

        // WHEN
        let subRenderer = createRenderer()
        subRenderer.loadTrack(content: content)
        subRenderer.setCanvasSize(size, scale: scale)

        // THEN
        XCTAssert(mockLibraryWrapper.setRendererSizeFunc.wasCalled)
        let argument = try XCTUnwrap(mockLibraryWrapper.setRendererSizeFunc.argument)
        XCTAssert(argument == (renderer, size * scale))
    }

    func test_setCanvasSize_whenSizeAndScaleAreSame_shouldNotSetRendererSize() throws {
        // GIVEN
        let library = OpaquePointer(bitPattern: 1)!
        let renderer = OpaquePointer(bitPattern: 2)!
        let content = "<CONTENT>"
        let size = CGSize(width: 1920, height: 1080)
        let scale = 3.0
        mockLibraryWrapper.libraryInitStub = library
        mockLibraryWrapper.rendererInitStub = renderer
        mockLibraryWrapper.readTrackStub = ASS_Track()

        // WHEN
        let subRenderer = createRenderer()
        subRenderer.loadTrack(content: content)
        subRenderer.setCanvasSize(size, scale: scale)
        mockLibraryWrapper.setRendererSizeFunc.reset()
        subRenderer.setCanvasSize(size, scale: scale)

        // THEN
        XCTAssertFalse(mockLibraryWrapper.setRendererSizeFunc.wasCalled)
    }

    func test_setTimeOffset_whenFrameWasLoaded_shouldReturnProcessedImage() throws {
        // GIVEN
        let library = OpaquePointer(bitPattern: 1)!
        let renderer = OpaquePointer(bitPattern: 2)!
        let content = "<CONTENT>"
        let size = CGSize(width: 1920, height: 1080)
        let scale = 3.0
        let rect = CGRect(x: 10, y: 10, width: 100, height: 100)
        let image = ProcessedImage(image: .from(color: .black), imageRect: rect)
        let scaledDownImage = ProcessedImage(image: image.image, imageRect: (rect / scale).integral)
        let assImage = ASS_Image()
        let changed = true
        mockLibraryWrapper.libraryInitStub = library
        mockLibraryWrapper.rendererInitStub = renderer
        mockLibraryWrapper.readTrackStub = ASS_Track()
        mockLibraryWrapper.renderImageStub = LibraryRenderResult(image: assImage, changed: changed)
        mockImagePipeline.processStub = image

        // WHEN
        let subRenderer = createRenderer()
        var images: [ProcessedImage?] = []
        subRenderer
            .framesPublisher()
            .dropFirst()
            .sink { images.append($0) }
            .store(in: &cancellables)
        subRenderer.loadTrack(content: content)
        subRenderer.setCanvasSize(size, scale: scale)
        images.removeAll()
        subRenderer.setTimeOffset(10)

        // THEN
        XCTAssert(mockLibraryWrapper.renderImageFunc.wasCalled)
        XCTAssert(mockImagePipeline.processFunc.wasCalled)
        XCTAssertEqual(images, [scaledDownImage])
    }

    func test_setTimeOffset_whenFrameWasNotLoaded_shouldReturnNil() throws {
        // GIVEN
        let library = OpaquePointer(bitPattern: 1)!
        let renderer = OpaquePointer(bitPattern: 2)!
        let content = "<CONTENT>"
        let scale = 3.0
        let size = CGSize(width: 1920, height: 1080)
        let rect = CGRect(x: 10, y: 10, width: 100, height: 100)
        let image = ProcessedImage(image: .from(color: .black), imageRect: rect)
        let scaledDownImage = ProcessedImage(image: image.image, imageRect: (rect / scale).integral)
        mockLibraryWrapper.libraryInitStub = library
        mockLibraryWrapper.rendererInitStub = renderer
        mockLibraryWrapper.readTrackStub = ASS_Track()
        mockLibraryWrapper.renderImageStub = LibraryRenderResult(image: ASS_Image(), changed: true)
        mockImagePipeline.processStub = image

        // WHEN
        let subRenderer = createRenderer()
        var images: [ProcessedImage?] = []
        subRenderer
            .framesPublisher()
            .dropFirst()
            .sink { images.append($0) }
            .store(in: &cancellables)
        subRenderer.loadTrack(content: content)
        subRenderer.setCanvasSize(size, scale: scale)
        images.removeAll()
        subRenderer.setTimeOffset(10)
        mockLibraryWrapper.renderImageStub = nil
        mockImagePipeline.processStub = nil
        subRenderer.setTimeOffset(20)

        // THEN
        XCTAssert(mockLibraryWrapper.renderImageFunc.wasCalled)
        XCTAssertEqual(images, [scaledDownImage, nil])
    }

    func test_setTimeOffset_whenFrameWasUnchanged_shouldNotReturnAnything() throws {
        // GIVEN
        let library = OpaquePointer(bitPattern: 1)!
        let renderer = OpaquePointer(bitPattern: 2)!
        let content = "<CONTENT>"
        let size = CGSize(width: 1920, height: 1080)
        let scale = 3.0
        let changed = false
        mockLibraryWrapper.libraryInitStub = library
        mockLibraryWrapper.rendererInitStub = renderer
        mockLibraryWrapper.readTrackStub = ASS_Track()
        mockLibraryWrapper.renderImageStub = LibraryRenderResult(image: ASS_Image(), changed: changed)

        // WHEN
        let subRenderer = createRenderer()
        var images: [ProcessedImage?] = []
        subRenderer
            .framesPublisher()
            .dropFirst()
            .sink { images.append($0) }
            .store(in: &cancellables)
        subRenderer.loadTrack(content: content)
        subRenderer.setCanvasSize(size, scale: scale)
        subRenderer.setTimeOffset(10)

        // THEN
        XCTAssert(mockLibraryWrapper.renderImageFunc.wasCalled)
        XCTAssertEqual(images, [])
    }

    func test_reloadFrame_shouldReloadFrameAtCurrentOffset() throws {
        // GIVEN
        let library = OpaquePointer(bitPattern: 1)!
        let renderer = OpaquePointer(bitPattern: 2)!
        let content = "<CONTENT>"
        let size = CGSize(width: 1920, height: 1080)
        let scale = 3.0
        let rect = CGRect(x: 10, y: 10, width: 100, height: 100)
        let image = ProcessedImage(image: .from(color: .black), imageRect: rect)
        let scaledDownImage = ProcessedImage(image: image.image, imageRect: (rect / scale).integral)
        let assImage = ASS_Image()
        let changed = true
        mockLibraryWrapper.libraryInitStub = library
        mockLibraryWrapper.rendererInitStub = renderer
        mockLibraryWrapper.readTrackStub = ASS_Track()
        mockLibraryWrapper.renderImageStub = LibraryRenderResult(image: assImage, changed: changed)
        mockImagePipeline.processStub = image

        // WHEN
        let subRenderer = createRenderer()
        var images: [ProcessedImage?] = []
        subRenderer
            .framesPublisher()
            .dropFirst()
            .sink { images.append($0) }
            .store(in: &cancellables)
        subRenderer.loadTrack(content: content)
        subRenderer.setCanvasSize(size, scale: scale)
        images.removeAll()
        subRenderer.setTimeOffset(10)
        subRenderer.reloadFrame()

        // THEN
        XCTAssert(mockLibraryWrapper.renderImageFunc.wasCalled)
        XCTAssert(mockImagePipeline.processFunc.wasCalled)
        XCTAssertEqual(images, [scaledDownImage, scaledDownImage])
    }

    func test_loadFrame_whenFrameWasLoaded_shouldReturnProcessedImage() throws {
        // GIVEN
        let library = OpaquePointer(bitPattern: 1)!
        let renderer = OpaquePointer(bitPattern: 2)!
        let content = "<CONTENT>"
        let size = CGSize(width: 1920, height: 1080)
        let scale = 3.0
        let rect = CGRect(x: 10, y: 10, width: 100, height: 100)
        let image = ProcessedImage(image: .from(color: .black), imageRect: rect)
        let scaledDownImage = ProcessedImage(image: image.image, imageRect: (rect / scale).integral)
        let assImage = ASS_Image()
        let changed = true
        mockLibraryWrapper.libraryInitStub = library
        mockLibraryWrapper.rendererInitStub = renderer
        mockLibraryWrapper.readTrackStub = ASS_Track()
        mockLibraryWrapper.renderImageStub = LibraryRenderResult(image: assImage, changed: changed)
        mockImagePipeline.processStub = image

        // WHEN
        let subRenderer = createRenderer()
        var processedImage: ProcessedImage?
        subRenderer.loadTrack(content: content)
        subRenderer.setCanvasSize(size, scale: scale)
        subRenderer.loadFrame(offset: 10) { processedImage = $0 }

        // THEN
        XCTAssert(mockLibraryWrapper.renderImageFunc.wasCalled)
        XCTAssert(mockImagePipeline.processFunc.wasCalled)
        XCTAssertEqual(processedImage, scaledDownImage)
    }

    func test_loadFrame_whenFrameWasNotLoaded_shouldReturnNil() throws {
        // GIVEN
        let library = OpaquePointer(bitPattern: 1)!
        let renderer = OpaquePointer(bitPattern: 2)!
        let content = "<CONTENT>"
        let scale = 3.0
        let size = CGSize(width: 1920, height: 1080)
        let rect = CGRect(x: 10, y: 10, width: 100, height: 100)
        let image = ProcessedImage(image: .from(color: .black), imageRect: rect)
        mockLibraryWrapper.libraryInitStub = library
        mockLibraryWrapper.rendererInitStub = renderer
        mockLibraryWrapper.readTrackStub = ASS_Track()
        mockLibraryWrapper.renderImageStub = LibraryRenderResult(image: ASS_Image(), changed: true)
        mockImagePipeline.processStub = image

        // WHEN
        let subRenderer = createRenderer()
        var processedImage: ProcessedImage?
        subRenderer.loadTrack(content: content)
        subRenderer.setCanvasSize(size, scale: scale)
        subRenderer.loadFrame(offset: 10) { processedImage = $0 }
        mockLibraryWrapper.renderImageStub = nil
        mockImagePipeline.processStub = nil
        subRenderer.loadFrame(offset: 20) { processedImage = $0 }

        // THEN
        XCTAssert(mockLibraryWrapper.renderImageFunc.wasCalled)
        XCTAssertNil(processedImage)
    }

    func test_loadFrame_whenFrameWasUnchanged_shouldReturnPreviouslyProcessedImage() throws {
        // GIVEN
        let library = OpaquePointer(bitPattern: 1)!
        let renderer = OpaquePointer(bitPattern: 2)!
        let content = "<CONTENT>"
        let size = CGSize(width: 1920, height: 1080)
        let scale = 3.0
        let rect = CGRect(x: 10, y: 10, width: 100, height: 100)
        let image = ProcessedImage(image: .from(color: .black), imageRect: rect)
        let scaledDownImage = ProcessedImage(image: image.image, imageRect: (rect / scale).integral)
        mockLibraryWrapper.libraryInitStub = library
        mockLibraryWrapper.rendererInitStub = renderer
        mockLibraryWrapper.readTrackStub = ASS_Track()
        mockImagePipeline.processStub = image

        // WHEN
        let subRenderer = createRenderer()
        var processedImage: ProcessedImage?
        subRenderer.loadTrack(content: content)
        subRenderer.setCanvasSize(size, scale: scale)

        mockLibraryWrapper.renderImageStub = LibraryRenderResult(image: ASS_Image(), changed: true)
        subRenderer.loadFrame(offset: 10) { processedImage = $0 }

        mockLibraryWrapper.renderImageStub = LibraryRenderResult(image: ASS_Image(), changed: false)
        subRenderer.loadFrame(offset: 20) { processedImage = $0 }

        // THEN
        XCTAssert(mockLibraryWrapper.renderImageFunc.wasCalled)
        XCTAssertEqual(processedImage, scaledDownImage)
    }
}

#if canImport(UIKit)
private extension CGImage {
    static func from(color: UIColor, size: CGSize = CGSize(width: 1, height: 1)) -> CGImage {
        let rect = CGRect(origin: .zero, size: size)
        UIGraphicsBeginImageContextWithOptions(rect.size, false, 0.0)
        color.setFill()
        UIRectFill(rect)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image!.cgImage!
    }
}
#elseif canImport(AppKit)
private extension CGImage {
    static func from(color: NSColor, size: NSSize = NSSize(width: 1, height: 1)) -> CGImage {
        let image = NSImage(size: size)
        image.lockFocus()
        color.drawSwatch(in: NSRect(origin: .zero, size: size))
        image.unlockFocus()
        return image.cgImage(forProposedRect: nil, context: nil, hints: nil)!
    }
}
#endif

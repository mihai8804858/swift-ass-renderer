import Foundation
import Testing
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif
import Combine
import CombineSchedulers
import SwiftLibass
import SwiftAssBlend
@testable import SwiftAssRenderer

extension MockLibraryWrapperSuites {
    final class AssSubtitlesRendererTests: @unchecked Sendable {
        private var mockQueue: MockDispatchQueue!
        private var mockLibraryWrapper: MockLibraryWrapper.Type!
        private var mockFontConfig: MockFontConfig!
        private var mockImagePipeline: MockImagePipeline!
        private var mockLogger: MockLogger!
        private var mockContentsLoader: MockContentsLoader!
        private var librarySetupFunc: FuncCheck<OpaquePointer>!
        private var rendererSetupFunc: FuncCheck<(OpaquePointer, OpaquePointer)>!
        private var cancellables = Set<AnyCancellable>()

        init() {
            MockLibraryWrapper.reset()
            mockQueue = MockDispatchQueue()
            mockLibraryWrapper = MockLibraryWrapper.self
            mockFontConfig = MockFontConfig()
            mockImagePipeline = MockImagePipeline()
            mockLogger = MockLogger()
            mockContentsLoader = MockContentsLoader()
            librarySetupFunc = FuncCheck<OpaquePointer>()
            rendererSetupFunc = FuncCheck<(OpaquePointer, OpaquePointer)>()
        }

        @MainActor
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

        @MainActor
        func createEvent(range: ClosedRange<TimeInterval>, text: inout [CChar]) -> ASS_Event {
            text.withUnsafeMutableBufferPointer { pointer in
                ASS_Event(
                    Start: Int64(range.lowerBound * 1000),
                    Duration: Int64((range.upperBound - range.lowerBound) * 1000),
                    ReadOrder: 0,
                    Layer: 0,
                    Style: 0,
                    Name: nil,
                    MarginL: 0,
                    MarginR: 0,
                    MarginV: 0,
                    Effect: nil,
                    Text: pointer.baseAddress,
                    render_priv: nil
                )
            }
        }

        @MainActor
        func createTrack(events: inout [ASS_Event]) -> ASS_Track {
            events.withUnsafeMutableBufferPointer { pointer in
                ASS_Track(
                    n_styles: 0,
                    max_styles: .max,
                    n_events: Int32(pointer.count),
                    max_events: .max,
                    styles: nil,
                    events: pointer.baseAddress,
                    style_format: nil,
                    event_format: nil,
                    track_type: 0,
                    PlayResX: 1920,
                    PlayResY: 1080,
                    Timer: 0,
                    WrapStyle: 0,
                    ScaledBorderAndShadow: 0,
                    Kerning: 0,
                    Language: nil,
                    YCbCrMatrix: YCBCR_DEFAULT,
                    default_style: 0,
                    name: nil,
                    library: nil,
                    parser_priv: nil,
                    LayoutResX: 1920,
                    LayoutResY: 1080
                )
            }
        }

        @Test
        @MainActor
        func test_init_shouldInitLibrary() throws {
            // WHEN
            _ = createRenderer()

            // THEN
            #expect(mockLibraryWrapper.libraryInitFunc.wasCalled)
        }

        @Test
        @MainActor
        func test_init_shouldInitRenderer() throws {
            // GIVEN
            let library = OpaquePointer(bitPattern: 1)!
            mockLibraryWrapper.libraryInitStub = library

            // WHEN
            _ = createRenderer()

            // THEN
            #expect(mockLibraryWrapper.rendererInitFunc.wasCalled(with: library))
        }

        @Test
        @MainActor
        func test_init_shouldCallLibrarySetup() throws {
            // GIVEN
            let library = OpaquePointer(bitPattern: 1)!
            let renderer = OpaquePointer(bitPattern: 2)!
            mockLibraryWrapper.libraryInitStub = library
            mockLibraryWrapper.rendererInitStub = renderer

            // WHEN
            _ = createRenderer()

            // THEN
            #expect(librarySetupFunc.wasCalled(with: library))
        }

        @Test
        @MainActor
        func test_init_shouldCallRendererSetup() throws {
            // GIVEN
            let library = OpaquePointer(bitPattern: 1)!
            let renderer = OpaquePointer(bitPattern: 2)!
            mockLibraryWrapper.libraryInitStub = library
            mockLibraryWrapper.rendererInitStub = renderer

            // WHEN
            _ = createRenderer()

            // THEN
            let argument = try #require(rendererSetupFunc.argument)
            #expect(rendererSetupFunc.wasCalled)
            #expect(argument == (library, renderer))
        }

        @Test
        @MainActor
        func test_init_shouldConfigureLoggerLibrary() throws {
            // GIVEN
            let library = OpaquePointer(bitPattern: 1)!
            mockLibraryWrapper.libraryInitStub = library

            // WHEN
            _ = createRenderer()

            // THEN
            #expect(mockLogger.configureLibraryFunc.wasCalled)
        }

        @Test
        @MainActor
        func test_init_shouldConfigureFonts() throws {
            // GIVEN
            let library = OpaquePointer(bitPattern: 1)!
            let renderer = OpaquePointer(bitPattern: 2)!
            mockLibraryWrapper.libraryInitStub = library
            mockLibraryWrapper.rendererInitStub = renderer

            // WHEN
            _ = createRenderer()

            // THEN
            #expect(mockFontConfig.configureFunc.wasCalled)
            let argument = try #require(mockFontConfig.configureFunc.argument)
            #expect(argument == (library, renderer))
        }

        @Test
        @MainActor
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
            #expect(mockLibraryWrapper.readTrackFunc.wasCalled)
            let argument = try #require(mockLibraryWrapper.readTrackFunc.argument)
            #expect(argument == (library, content))
        }

        @Test
        @MainActor
        func test_reloadTrackContent_shouldReadTrackAndLoadLastKnownOffset() throws {
            // GIVEN
            let library = OpaquePointer(bitPattern: 1)!
            let renderer = OpaquePointer(bitPattern: 2)!
            let content = "<CONTENT>"
            let newContent = "<NEW_CONTENT>"
            let offset = 10.0
            mockLibraryWrapper.libraryInitStub = library
            mockLibraryWrapper.rendererInitStub = renderer
            mockLibraryWrapper.readTrackStub = ASS_Track()

            let subRenderer = createRenderer()
            subRenderer.loadTrack(content: content)
            subRenderer.setTimeOffset(offset)

            mockLibraryWrapper.readTrackFunc.reset()
            mockLibraryWrapper.renderImageFunc.reset()

            // WHEN
            subRenderer.reloadTrack(content: newContent)

            // THEN
            #expect(mockLibraryWrapper.readTrackFunc.wasCalled)
            #expect(mockLibraryWrapper.renderImageFunc.wasCalled)
            let contentArgument = try #require(mockLibraryWrapper.readTrackFunc.argument)
            let offsetArgument = try #require(mockLibraryWrapper.renderImageFunc.argument)
            #expect(contentArgument.1 == newContent)
            #expect(offsetArgument.2 == offset)
        }

        @Test
        @MainActor
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
            #expect(mockLibraryWrapper.readTrackFunc.wasCalled)
            let argument = try #require(mockLibraryWrapper.readTrackFunc.argument)
            #expect(argument == (library, content))
        }

        @Test
        @MainActor
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
            mockLibraryWrapper.readTrackStub = ASS_Track()
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
            #expect(mockLibraryWrapper.readTrackFunc.wasCalled)
            #expect(mockLibraryWrapper.renderImageFunc.wasCalled)
            #expect(mockContentsLoader.loadContentsFunc.wasCalled)
            let contentArgument = try #require(mockLibraryWrapper.readTrackFunc.argument)
            let offsetArgument = try #require(mockLibraryWrapper.renderImageFunc.argument)
            let urlArgument = try #require(mockContentsLoader.loadContentsFunc.argument)
            #expect(contentArgument.1 == newContent)
            #expect(offsetArgument.2 == offset)
            #expect(urlArgument == newURL)
        }

        @Test
        @MainActor
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
            #expect(mockLibraryWrapper.rendererDoneFunc.wasCalled)
        }

        @Test
        @MainActor
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
            #expect(mockLibraryWrapper.libraryDoneFunc.wasCalled)
        }

        @Test
        @MainActor
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
            #expect(mockLibraryWrapper.setRendererSizeFunc.wasCalled)
            let argument = try #require(mockLibraryWrapper.setRendererSizeFunc.argument)
            #expect(argument == (renderer, size * scale))
        }

        @Test
        @MainActor
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
            #expect(!mockLibraryWrapper.setRendererSizeFunc.wasCalled)
        }

        @Test
        @MainActor
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
            #expect(mockLibraryWrapper.renderImageFunc.wasCalled)
            #expect(mockImagePipeline.processFunc.wasCalled)
            #expect(images == [scaledDownImage])
        }

        @Test
        @MainActor
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
            #expect(mockLibraryWrapper.renderImageFunc.wasCalled)
            #expect(images == [scaledDownImage, nil])
        }

        @Test
        @MainActor
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
            #expect(mockLibraryWrapper.renderImageFunc.wasCalled)
            #expect(images == [])
        }

        @Test
        @MainActor
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
            #expect(mockLibraryWrapper.renderImageFunc.wasCalled)
            #expect(mockImagePipeline.processFunc.wasCalled)
            #expect(images == [scaledDownImage, scaledDownImage])
        }

        @Test
        @MainActor
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
            nonisolated(unsafe) var processedImage: ProcessedImage?
            subRenderer.loadTrack(content: content)
            subRenderer.setCanvasSize(size, scale: scale)
            subRenderer.loadFrame(offset: 10) { processedImage = $0 }

            // THEN
            #expect(mockLibraryWrapper.renderImageFunc.wasCalled)
            #expect(mockImagePipeline.processFunc.wasCalled)
            #expect(processedImage == scaledDownImage)
        }

        @Test
        @MainActor
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
            nonisolated(unsafe) var processedImage: ProcessedImage?
            subRenderer.loadTrack(content: content)
            subRenderer.setCanvasSize(size, scale: scale)
            subRenderer.loadFrame(offset: 10) { processedImage = $0 }
            mockLibraryWrapper.renderImageStub = nil
            mockImagePipeline.processStub = nil
            subRenderer.loadFrame(offset: 20) { processedImage = $0 }

            // THEN
            #expect(mockLibraryWrapper.renderImageFunc.wasCalled)
            #expect(processedImage == nil)
        }

        @Test
        @MainActor
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
            nonisolated(unsafe) var processedImage: ProcessedImage?
            subRenderer.loadTrack(content: content)
            subRenderer.setCanvasSize(size, scale: scale)

            mockLibraryWrapper.renderImageStub = LibraryRenderResult(image: ASS_Image(), changed: true)
            subRenderer.loadFrame(offset: 10) { processedImage = $0 }

            mockLibraryWrapper.renderImageStub = LibraryRenderResult(image: ASS_Image(), changed: false)
            subRenderer.loadFrame(offset: 20) { processedImage = $0 }

            // THEN
            #expect(mockLibraryWrapper.renderImageFunc.wasCalled)
            #expect(processedImage == scaledDownImage)
        }

        @Test
        @MainActor
        func test_dialogues_whenTrackIsMissing_shouldReturnNoDialogues() {
            // GIVEN
            let library = OpaquePointer(bitPattern: 1)!
            let renderer = OpaquePointer(bitPattern: 2)!
            mockLibraryWrapper.libraryInitStub = library
            mockLibraryWrapper.rendererInitStub = renderer

            // WHEN
            let subRenderer = createRenderer()
            let dialogues = subRenderer.dialogues(at: 0.0)

            // THEN
            #expect(dialogues == [])
        }

        @Test
        @MainActor
        func test_dialogues_whenEventsAreMissing_shouldReturnNoDialogues() {
            // GIVEN
            let library = OpaquePointer(bitPattern: 1)!
            let renderer = OpaquePointer(bitPattern: 2)!
            mockLibraryWrapper.libraryInitStub = library
            mockLibraryWrapper.rendererInitStub = renderer
            mockLibraryWrapper.readTrackStub = ASS_Track()

            // WHEN
            let subRenderer = createRenderer()
            subRenderer.loadTrack(content: "<CONTENT>")
            let dialogues = subRenderer.dialogues(at: 0.0)

            // THEN
            #expect(dialogues == [])
        }

        @Test
        @MainActor
        func test_dialogues_whenEventsAreNotInRange_shouldReturnNoDialogues() {
            // GIVEN
            let library = OpaquePointer(bitPattern: 1)!
            let renderer = OpaquePointer(bitPattern: 2)!
            var eventsText = [
                "text1",
                "text2",
                "text3",
                "text4"
            ].compactMap { text in
                text.cString(using: .utf8)
            }
            var events = [
                createEvent(range: 1...3, text: &eventsText[0]),
                createEvent(range: 11...13, text: &eventsText[1]),
                createEvent(range: 12...14, text: &eventsText[2]),
                createEvent(range: 21...24, text: &eventsText[3])
            ]
            let track = createTrack(events: &events)
            mockLibraryWrapper.libraryInitStub = library
            mockLibraryWrapper.rendererInitStub = renderer
            mockLibraryWrapper.readTrackStub = track

            // WHEN
            let subRenderer = createRenderer()
            subRenderer.loadTrack(content: "<CONTENT>")
            let dialogues = subRenderer.dialogues(at: 15)

            // THEN
            #expect(dialogues == [])
        }

        @Test
        @MainActor
        func test_dialogues_whenEventsAreInRange_shouldReturnDialogues() {
            // GIVEN
            let library = OpaquePointer(bitPattern: 1)!
            let renderer = OpaquePointer(bitPattern: 2)!
            var eventsText = [
                "text1",
                "text2",
                "text3",
                "text4"
            ].compactMap { text in
                text.cString(using: .utf8)
            }
            var events = [
                createEvent(range: 1...3, text: &eventsText[0]),
                createEvent(range: 11...13, text: &eventsText[1]),
                createEvent(range: 12...14, text: &eventsText[2]),
                createEvent(range: 21...24, text: &eventsText[3])
            ]
            let track = createTrack(events: &events)
            mockLibraryWrapper.libraryInitStub = library
            mockLibraryWrapper.rendererInitStub = renderer
            mockLibraryWrapper.readTrackStub = track

            // WHEN
            let subRenderer = createRenderer()
            subRenderer.loadTrack(content: "<CONTENT>")
            let dialogues = subRenderer.dialogues(at: 12.5)

            // THEN
            #expect(dialogues == ["text2", "text3"])
        }
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

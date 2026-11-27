import Foundation
import Testing
import ConcurrencyExtras
import SwiftLibass
@testable import SwiftAssRenderer

struct LibraryWrapperTests {
    private let iterations = 10_000

    private var cachesDirectory: URL {
        if #available(iOS 16.0, tvOS 16.0, visionOS 1.0, macOS 13.0, *) {
            URL.cachesDirectory
        } else {
            FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        }
    }

    @Test
    func test_libraryInit_isThreadSafety() {
        DispatchQueue.concurrentPerform(iterations: iterations) { _ in
            _ = LibraryWrapper.libraryInit()
        }
    }

    @Test
    func test_libraryDone_isThreadSafety() throws {
        DispatchQueue.concurrentPerform(iterations: iterations) { _ in
            guard let library = LibraryWrapper.libraryInit() else { return }
            LibraryWrapper.libraryDone(library)
        }
    }

    @Test
    func test_rendererInit_isThreadSafety() throws {
        let library = UncheckedSendable(try #require(LibraryWrapper.libraryInit()))
        DispatchQueue.concurrentPerform(iterations: iterations) { _ in
            _ = LibraryWrapper.rendererInit(library.value)
        }
    }

    @Test
    func test_rendererDone_isThreadSafety() throws {
        let library = UncheckedSendable(try #require(LibraryWrapper.libraryInit()))
        DispatchQueue.concurrentPerform(iterations: iterations) { _ in
            guard let renderer = LibraryWrapper.rendererInit(library.value) else { return }
            LibraryWrapper.rendererDone(renderer)
        }
    }

    @Test
    func test_setLogCallback_isThreadSafety() throws {
        let library = UncheckedSendable(try #require(LibraryWrapper.libraryInit()))
        let sink = LibraryLogSink { _, _ in }
        DispatchQueue.concurrentPerform(iterations: iterations) { _ in
            LibraryWrapper.setLogCallback(library.value, sink: sink)
        }
        LibraryWrapper.libraryDone(library.value)
    }

    @Test
    func test_setLogCallback_routesMessagesToTheSinkOfTheirLibrary() throws {
        let first = MessageCollector()
        let second = MessageCollector()
        let firstSink = LibraryLogSink { _, message in first.append(message) }
        let secondSink = LibraryLogSink { _, message in second.append(message) }
        let firstLibrary = try #require(LibraryWrapper.libraryInit())
        let secondLibrary = try #require(LibraryWrapper.libraryInit())
        LibraryWrapper.setLogCallback(firstLibrary, sink: firstSink)
        LibraryWrapper.setLogCallback(secondLibrary, sink: secondSink)

        // No [Events] Format line, so libass reports that it falls back to the default format.
        let content = "[Script Info]\nScriptType: v4.00+\n\n"
            + "[Events]\nDialogue: 0,0:00:00.00,0:00:01.00,Default,,0,0,0,,Hi\n"
        _ = LibraryWrapper.readTrack(firstLibrary, content: content)

        #expect(!first.messages.isEmpty)
        #expect(second.messages.isEmpty, "\(second.messages)")

        LibraryWrapper.libraryDone(firstLibrary)
        LibraryWrapper.libraryDone(secondLibrary)
    }

    @Test
    func test_setRendererSize_isThreadSafety() throws {
        let library = try #require(LibraryWrapper.libraryInit())
        let renderer = UncheckedSendable(try #require(LibraryWrapper.rendererInit(library)))
        DispatchQueue.concurrentPerform(iterations: iterations) { _ in
            LibraryWrapper.setRendererSize(renderer.value, size: CGSize(width: 1920, height: 1080))
        }
    }

    @Test
    func test_setExtractFonts_isThreadSafety() throws {
        let library = UncheckedSendable(try #require(LibraryWrapper.libraryInit()))
        DispatchQueue.concurrentPerform(iterations: iterations) { _ in
            LibraryWrapper.setExtractFonts(library.value, extract: .random())
        }
    }

    @Test
    func test_setFonts_coreText_isThreadSafety() throws {
        let library = try #require(LibraryWrapper.libraryInit())
        let renderer = UncheckedSendable(try #require(LibraryWrapper.rendererInit(library)))
        DispatchQueue.concurrentPerform(iterations: iterations) { _ in
            LibraryWrapper.setFonts(
                renderer.value,
                provider: .coreText,
                defaultFont: "Arial",
                defaultFamily: "Regular"
            )
        }
    }

    @Test
    func test_setFonts_fontConfig_isThreadSafety() throws {
        let library = try #require(LibraryWrapper.libraryInit())
        let renderer = UncheckedSendable(try #require(LibraryWrapper.rendererInit(library)))
        DispatchQueue.concurrentPerform(iterations: iterations) { _ in
            LibraryWrapper.setFonts(
                renderer.value,
                provider: .fontConfig,
                configPath: cachesDirectory.appendingPathComponent("fonts.conf").path,
                defaultFont: "Arial",
                defaultFamily: "Regular"
            )
        }
    }

    @Test
    func test_readTrack_isThreadSafety() throws {
        let contentsPath = try #require(Bundle.module.resourceURL?.appendingPathComponent("Subs/en.ass"))
        let content = try String(contentsOfFile: contentsPath.path)
        let library = UncheckedSendable(try #require(LibraryWrapper.libraryInit()))
        DispatchQueue.concurrentPerform(iterations: iterations) { _ in
            _ = LibraryWrapper.readTrack(library.value, content: content)
        }
    }

    @Test
    func test_renderImage_isThreadSafety() throws {
        let contentsPath = try #require(Bundle.module.resourceURL?.appendingPathComponent("Subs/en.ass"))
        let content = try String(contentsOfFile: contentsPath.path)
        let library = try #require(LibraryWrapper.libraryInit())
        let renderer = UncheckedSendable(try #require(LibraryWrapper.rendererInit(library)))
        nonisolated(unsafe) var track = try #require(LibraryWrapper.readTrack(library, content: content))
        LibraryWrapper.setRendererSize(renderer.value, size: CGSize(width: 320, height: 240))
        DispatchQueue.concurrentPerform(iterations: iterations) { _ in
            _ = LibraryWrapper.renderImage(renderer.value, track: &track, at: 40.0)
        }
    }
}

private final class MessageCollector: @unchecked Sendable {
    private let lock = NSLock()
    private var storage: [String] = []

    var messages: [String] {
        lock.lock()
        defer { lock.unlock() }
        return storage
    }

    func append(_ message: String) {
        lock.lock()
        storage.append(message)
        lock.unlock()
    }
}

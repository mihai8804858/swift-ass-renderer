import XCTest
@testable import SwiftAssRenderer

#if hasAttribute(retroactive)
extension OpaquePointer: @unchecked @retroactive Sendable {}
#endif

final class LibraryWrapperTests: XCTestCase {
    private let iterations = 10_000

    private var cachesDirectory: URL {
        if #available(iOS 16.0, tvOS 16.0, visionOS 1.0, macOS 13.0, *) {
            URL.cachesDirectory
        } else {
            FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        }
    }

    func test_libraryLogger_isThreadSafety() {
        DispatchQueue.concurrentPerform(iterations: iterations) { _ in
            LibraryWrapper.libraryLogger = { _, _ in }
        }
    }

    func test_libraryInit_isThreadSafety() {
        DispatchQueue.concurrentPerform(iterations: iterations) { _ in
            _ = LibraryWrapper.libraryInit()
        }
    }

    func test_libraryDone_isThreadSafety() throws {
        DispatchQueue.concurrentPerform(iterations: iterations) { _ in
            guard let library = LibraryWrapper.libraryInit() else { return }
            LibraryWrapper.libraryDone(library)
        }
    }

    func test_rendererInit_isThreadSafety() throws {
        let library = try XCTUnwrap(LibraryWrapper.libraryInit())
        DispatchQueue.concurrentPerform(iterations: iterations) { _ in
            _ = LibraryWrapper.rendererInit(library)
        }
    }

    func test_rendererDone_isThreadSafety() throws {
        let library = try XCTUnwrap(LibraryWrapper.libraryInit())
        DispatchQueue.concurrentPerform(iterations: iterations) { _ in
            guard let renderer = LibraryWrapper.rendererInit(library) else { return }
            LibraryWrapper.rendererDone(renderer)
        }
    }

    func test_setLogCallback_isThreadSafety() throws {
        let library = try XCTUnwrap(LibraryWrapper.libraryInit())
        DispatchQueue.concurrentPerform(iterations: iterations) { _ in
            LibraryWrapper.setLogCallback(library)
        }
    }

    func test_setRendererSize_isThreadSafety() throws {
        let library = try XCTUnwrap(LibraryWrapper.libraryInit())
        let renderer = try XCTUnwrap(LibraryWrapper.rendererInit(library))
        DispatchQueue.concurrentPerform(iterations: iterations) { _ in
            LibraryWrapper.setRendererSize(renderer, size: CGSize(width: 1920, height: 1080))
        }
    }

    func test_setExtractFonts_isThreadSafety() throws {
        let library = try XCTUnwrap(LibraryWrapper.libraryInit())
        DispatchQueue.concurrentPerform(iterations: iterations) { _ in
            LibraryWrapper.setExtractFonts(library, extract: .random())
        }
    }

    func test_setFonts_coreText_isThreadSafety() throws {
        let library = try XCTUnwrap(LibraryWrapper.libraryInit())
        let renderer = try XCTUnwrap(LibraryWrapper.rendererInit(library))
        DispatchQueue.concurrentPerform(iterations: iterations) { _ in
            LibraryWrapper.setFonts(
                renderer,
                provider: .coreText,
                defaultFont: "Arial",
                defaultFamily: "Regular"
            )
        }
    }

    func test_setFonts_fontConfig_isThreadSafety() throws {
        let library = try XCTUnwrap(LibraryWrapper.libraryInit())
        let renderer = try XCTUnwrap(LibraryWrapper.rendererInit(library))
        DispatchQueue.concurrentPerform(iterations: iterations) { _ in
            LibraryWrapper.setFonts(
                renderer,
                provider: .fontConfig,
                configPath: cachesDirectory.appendingPathComponent("fonts.conf").path,
                defaultFont: "Arial",
                defaultFamily: "Regular"
            )
        }
    }

    func test_readTrack_isThreadSafety() throws {
        let contentsPath = try XCTUnwrap(Bundle.module.resourceURL?.appendingPathComponent("Subs/en.ass"))
        let content = try String(contentsOfFile: contentsPath.path)
        let library = try XCTUnwrap(LibraryWrapper.libraryInit())
        DispatchQueue.concurrentPerform(iterations: iterations) { _ in
            _ = LibraryWrapper.readTrack(library, content: content)
        }
    }

    func test_renderImage_isThreadSafety() throws {
        let contentsPath = try XCTUnwrap(Bundle.module.resourceURL?.appendingPathComponent("Subs/en.ass"))
        let content = try String(contentsOfFile: contentsPath.path)
        let library = try XCTUnwrap(LibraryWrapper.libraryInit())
        let renderer = try XCTUnwrap(LibraryWrapper.rendererInit(library))
        var track = try XCTUnwrap(LibraryWrapper.readTrack(library, content: content))
        LibraryWrapper.setRendererSize(renderer, size: CGSize(width: 320, height: 240))
        DispatchQueue.concurrentPerform(iterations: iterations) { _ in
            _ = LibraryWrapper.renderImage(renderer, track: &track, at: 40.0)
        }
    }
}

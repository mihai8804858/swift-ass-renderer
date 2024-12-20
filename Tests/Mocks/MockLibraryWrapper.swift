import Foundation
import SwiftLibass
@testable import SwiftAssRenderer

final class MockLibraryWrapper: LibraryWrapperType {
    nonisolated(unsafe) static var libraryLogger: (Int, String) -> Void = { _, _ in }

    static let setLogCallbackFunc = FuncCheck<OpaquePointer>()
    static func setLogCallback(_ library: OpaquePointer) {
        setLogCallbackFunc.call(library)
    }

    static let libraryInitFunc = FuncCheck<Void>()
    nonisolated(unsafe) static var libraryInitStub: OpaquePointer?
    static func libraryInit() -> OpaquePointer? {
        libraryInitFunc.call()
        return libraryInitStub
    }

    static let libraryDoneFunc = FuncCheck<OpaquePointer>()
    static func libraryDone(_ library: OpaquePointer) {
        libraryDoneFunc.call(library)
    }

    static let rendererInitFunc = FuncCheck<OpaquePointer>()
    nonisolated(unsafe) static var rendererInitStub: OpaquePointer?
    static func rendererInit(_ library: OpaquePointer) -> OpaquePointer? {
        rendererInitFunc.call(library)
        return rendererInitStub
    }

    static let rendererDoneFunc = FuncCheck<OpaquePointer>()
    static func rendererDone(_ renderer: OpaquePointer) {
        rendererDoneFunc.call(renderer)
    }

    static let setRendererSizeFunc = FuncCheck<(OpaquePointer, CGSize)>()
    static func setRendererSize(_ renderer: OpaquePointer, size: CGSize) {
        setRendererSizeFunc.call((renderer, size))
    }

    static let setExtractFontsFunc = FuncCheck<(OpaquePointer, Bool)>()
    static func setExtractFonts(_ library: OpaquePointer, extract: Bool) {
        setExtractFontsFunc.call((library, extract))
    }

    static let setFontsFunc = FuncCheck<(OpaquePointer, FontProvider, String?, String?, String?)>()
    static func setFonts(
        _ renderer: OpaquePointer,
        provider: FontProvider,
        configPath: String?,
        defaultFont: String?,
        defaultFamily: String?
    ) {
        setFontsFunc.call((renderer, provider, configPath, defaultFont, defaultFamily))
    }

    static let readTrackFunc = FuncCheck<(OpaquePointer, String)>()
    nonisolated(unsafe) static var readTrackStub: ASS_Track?
    static func readTrack(_ library: OpaquePointer, content: String) -> ASS_Track? {
        readTrackFunc.call((library, content))
        return readTrackStub
    }

    static let renderImageFunc = FuncCheck<(OpaquePointer, ASS_Track, TimeInterval)>()
    nonisolated(unsafe) static var renderImageStub: LibraryRenderResult?
    static func renderImage(
        _ renderer: OpaquePointer,
        track: inout ASS_Track,
        at offset: TimeInterval
    ) -> LibraryRenderResult? {
        renderImageFunc.call((renderer, track, offset))
        return renderImageStub
    }
}

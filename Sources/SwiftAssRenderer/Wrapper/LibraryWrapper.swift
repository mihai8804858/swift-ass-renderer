import Foundation
@preconcurrency import SwiftLibass

struct LibraryRenderResult: Sendable {
    let image: ASS_Image
    let changed: Bool
}

extension FontProvider {
    var assFontProvider: Int32 {
        switch self {
        case .fontConfig: Int32(ASS_FONTPROVIDER_FONTCONFIG.rawValue)
        case .coreText: Int32(ASS_FONTPROVIDER_CORETEXT.rawValue)
        }
    }
}

protocol LibraryWrapperType: Sendable {
    static var libraryLogger: (Int, String) -> Void { get set }
    static func setLogCallback(_ library: OpaquePointer)

    static func libraryInit() -> OpaquePointer?
    static func libraryDone(_ library: OpaquePointer)

    static func rendererInit(_ library: OpaquePointer) -> OpaquePointer?
    static func rendererDone(_ renderer: OpaquePointer)

    static func setRendererSize(_ renderer: OpaquePointer, size: CGSize)
    static func setExtractFonts(_ library: OpaquePointer, extract: Bool)
    static func setFonts(
        _ renderer: OpaquePointer,
        provider: FontProvider,
        configPath: String?,
        defaultFont: String?,
        defaultFamily: String?
    )

    static func readTrack(_ library: OpaquePointer, content: String) -> ASS_Track?

    static func renderImage(
        _ renderer: OpaquePointer,
        track: inout ASS_Track,
        at offset: TimeInterval
    ) -> LibraryRenderResult?
}

enum LibraryWrapper: LibraryWrapperType {
    private static let lock = NSLock()

    nonisolated(unsafe) static var libraryLogger: (Int, String) -> Void = { _, message in
        print("[swift-ass] \(message)")
    }

    static func libraryInit() -> OpaquePointer? {
        withLock(lock) {
            ass_library_init()
        }
    }

    static func libraryDone(_ library: OpaquePointer) {
        withLock(lock) {
            ass_library_done(library)
        }
    }

    static func rendererInit(_ library: OpaquePointer) -> OpaquePointer? {
        withLock(lock) {
            ass_renderer_init(library)
        }
    }

    static func rendererDone(_ renderer: OpaquePointer) {
        withLock(lock) {
            ass_renderer_done(renderer)
        }
    }

    static func setLogCallback(_ library: OpaquePointer) {
        withLock(lock) {
            ass_set_message_cb(library, { messageLevel, messageString, messageArgs, _ in
                guard let messageString else { return }
                let message = String(cString: messageString)
                if let messageArgs {
                    let formattedMessage = NSString(format: message, arguments: messageArgs) as String
                    LibraryWrapper.libraryLogger(Int(messageLevel), formattedMessage)
                } else {
                    LibraryWrapper.libraryLogger(Int(messageLevel), message)
                }
            }, nil)
        }
    }

    static func setRendererSize(_ renderer: OpaquePointer, size: CGSize) {
        withLock(lock) {
            ass_set_frame_size(renderer, Int32(size.width), Int32(size.height))
        }
    }

    static func setExtractFonts(_ library: OpaquePointer, extract: Bool) {
        withLock(lock) {
            ass_set_extract_fonts(library, extract ? 1 : 0)
        }
    }

    static func setFonts(
        _ renderer: OpaquePointer,
        provider: FontProvider,
        configPath: String? = nil,
        defaultFont: String? = nil,
        defaultFamily: String? = nil
    ) {
        withLock(lock) {
            let defaultFont = defaultFont.flatMap { $0.cString(using: .utf8) }
            let defaultFamily = defaultFamily.flatMap { $0.cString(using: .utf8) }
            let fontConfig = configPath.flatMap { $0.cString(using: .utf8) }
            let update: Int32 = 1
            ass_set_fonts(renderer, defaultFont, defaultFamily, provider.assFontProvider, fontConfig, update)
        }
    }

    static func readTrack(_ library: OpaquePointer, content: String) -> ASS_Track? {
        withLock(lock) {
            guard var buffer = content.cString(using: .utf8) else { return nil }
            return ass_read_memory(library, &buffer, buffer.count, nil).pointee
        }
    }

    static func renderImage(
        _ renderer: OpaquePointer,
        track: inout ASS_Track,
        at offset: TimeInterval
    ) -> LibraryRenderResult? {
        withLock(lock) {
            var changed: Int32 = 0
            let millisecond = Int64(offset * 1000)
            guard let frame = ass_render_frame(renderer, &track, millisecond, &changed) else { return nil }

            return LibraryRenderResult(image: frame.pointee, changed: changed != 0)
        }
    }
}

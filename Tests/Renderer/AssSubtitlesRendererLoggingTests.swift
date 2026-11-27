import Foundation
import Testing
@testable import SwiftAssRenderer

struct AssSubtitlesRendererLoggingTests {
    // No [Events] Format line, so libass reports that it falls back to the default format.
    private let trackWithoutEventFormat = """
    [Script Info]
    ScriptType: v4.00+

    [Events]
    Dialogue: 0,0:00:00.00,0:00:01.00,Default,,0,0,0,,Hi
    """
    private let fallbackMessage = "No event format found"

    @Test
    @MainActor
    func test_eachRendererReceivesOnlyMessagesFromItsOwnLibrary() async throws {
        let fontsPath = try #require(Bundle.module.resourceURL).appendingPathComponent("Fonts")
        let first = MessageLog()
        let second = MessageLog()
        let firstRenderer = AssSubtitlesRenderer(
            fontConfig: FontConfig(fontsPath: fontsPath, fontProvider: .coreText),
            logOutput: .custom { first.append($0.message) }
        )
        let secondRenderer = AssSubtitlesRenderer(
            fontConfig: FontConfig(fontsPath: fontsPath, fontProvider: .coreText),
            logOutput: .custom { second.append($0.message) }
        )
        await drainWorkQueue(of: firstRenderer)
        await drainWorkQueue(of: secondRenderer)

        firstRenderer.loadTrack(content: trackWithoutEventFormat)
        await drainWorkQueue(of: firstRenderer)

        #expect(first.messages.contains { $0.contains(fallbackMessage) }, "\(first.messages)")
        #expect(!second.messages.contains { $0.contains(fallbackMessage) }, "\(second.messages)")
    }

    /// A frame request queues behind everything the renderer's work queue already holds.
    @MainActor
    private func drainWorkQueue(of renderer: AssSubtitlesRenderer) async {
        await withCheckedContinuation { continuation in
            renderer.loadFrame(offset: 0) { _ in continuation.resume() }
        }
    }
}

private final class MessageLog: @unchecked Sendable {
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

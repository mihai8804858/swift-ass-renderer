import XCTest
import SwiftUI
import SwiftLibass
import SnapshotTesting
@testable import SwiftAssRenderer

@available(iOS 16.0, tvOS 16.0, visionOS 1.0, macOS 13.0, macCatalyst 16.0, *)
final class AccelerateImagePipelineTests: PipelineTestCase {
    private let pipeline = AccelerateImagePipeline()
    private let offsets: [TimeInterval] = [
        40.0,
        72.72,
        374.52,
        389.79,
        392.08,
        406.84,
        409.43,
        813.64,
        832.70,
        837.94,
        862.48,
        1354.62
    ]

    func test_processImage_fontConfig_shouldNotCrash() throws {
        for subtitle in ["en", "ru", "ar"] {
            try setup(fontProvider: .fontConfig, subtitle: subtitle)
            for event in Array(UnsafeBufferPointer(start: track.events, count: Int(track.n_events))) {
                _ = render(offset: TimeInterval(event.Start) / 1000, pipeline: pipeline)
            }
        }
    }

    func test_processImage_coreText_shouldNotCrash() throws {
        for subtitle in ["en", "ru", "ar"] {
            try setup(fontProvider: .coreText, subtitle: subtitle)
            for event in Array(UnsafeBufferPointer(start: track.events, count: Int(track.n_events))) {
                _ = render(offset: TimeInterval(event.Start) / 1000, pipeline: pipeline)
            }
        }
    }
}

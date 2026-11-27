import Foundation
import Testing
import SwiftUI
import SwiftLibass
import SnapshotTesting
@testable import SwiftAssRenderer

struct AccelerateImagePipelineTests {
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

    @Test
    @available(iOS 16.0, tvOS 16.0, visionOS 1.0, macOS 13.0, macCatalyst 16.0, *)
    func test_processImage_fontConfig_shouldNotCrash() throws {
        let pipeline = AccelerateImagePipeline()
        var harness = PipelineHarness()
        for subtitle in ["en", "ru", "ar"] {
            try harness.setup(fontProvider: .fontConfig, subtitle: subtitle)
            for event in harness.events {
                _ = harness.render(offset: TimeInterval(event.Start) / 1000, pipeline: pipeline)
            }
        }
    }

    @Test
    @available(iOS 16.0, tvOS 16.0, visionOS 1.0, macOS 13.0, macCatalyst 16.0, *)
    func test_processImage_coreText_shouldNotCrash() throws {
        let pipeline = AccelerateImagePipeline()
        var harness = PipelineHarness()
        for subtitle in ["en", "ru", "ar"] {
            try harness.setup(fontProvider: .coreText, subtitle: subtitle)
            for event in harness.events {
                _ = harness.render(offset: TimeInterval(event.Start) / 1000, pipeline: pipeline)
            }
        }
    }
}

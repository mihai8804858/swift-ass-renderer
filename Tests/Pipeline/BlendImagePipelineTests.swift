import Foundation
import Testing
import SwiftUI
import SwiftLibass
import SnapshotTesting
@testable import SwiftAssRenderer

struct BlendImagePipelineTests {
    private let pipeline = BlendImagePipeline()
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
    func test_processImage() throws {
        var harness = PipelineHarness()
        for subtitle in ["en", "ru", "ar"] {
            try harness.setup(fontProvider: .fontConfig, subtitle: subtitle)
            for offset in offsets {
                let rendered = harness.render(offset: offset, pipeline: pipeline)
                let image = try #require(rendered)
                assertSnapshot(
                    of: harness.value(image: image),
                    as: .image,
                    named: harness.snapshotName(offset: offset),
                    snapshotDirectory: snapshotsDirectory(pathComponents: platformName(), subtitle)
                )
            }
        }
    }

    @Test
    func test_processImage_fontConfig_shouldNotCrash() throws {
        var harness = PipelineHarness()
        for subtitle in ["en", "ru", "ar"] {
            try harness.setup(fontProvider: .fontConfig, subtitle: subtitle)
            for event in harness.events {
                _ = harness.render(offset: TimeInterval(event.Start) / 1000, pipeline: pipeline)
            }
        }
    }

    @Test
    func test_processImage_coreText_shouldNotCrash() throws {
        var harness = PipelineHarness()
        for subtitle in ["en", "ru", "ar"] {
            try harness.setup(fontProvider: .coreText, subtitle: subtitle)
            for event in harness.events {
                _ = harness.render(offset: TimeInterval(event.Start) / 1000, pipeline: pipeline)
            }
        }
    }
}

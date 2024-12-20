import CoreGraphics
import SwiftLibass

/// Pipeline that processed an `ASS_Image` into a ``ProcessedImage`` that can be drawn on the screen.
public protocol ImagePipelineType: Sendable {
    func process(images: [ASS_Image], boundingRect: CGRect) -> ProcessedImage?
}

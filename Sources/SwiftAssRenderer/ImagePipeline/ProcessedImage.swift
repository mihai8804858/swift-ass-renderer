import CoreGraphics

/// Processed image bitmap and the rect where the image should be drawn in the subtitles canvas.
public struct ProcessedImage: Equatable {
    public let image: CGImage
    public let imageRect: CGRect
}

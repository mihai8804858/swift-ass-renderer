import CoreGraphics
import SwiftLibass
import SwiftAssBlend

/// Pipeline that processed an `ASS_Image` into a ``ProcessedImage`` 
/// by alpha blending in place all the layers one by one.
public final class BlendImagePipeline: ImagePipelineType {
    public init() {}

    public func process(images: [ASS_Image], boundingRect: CGRect) -> ProcessedImage? {
        guard var image = images.first else { return nil }
        let blendResult = renderBlend(&image)
        guard blendResult.buffer != nil else { return nil }

        return makeCGImage(
            buffer: blendResult.buffer,
            size: boundingRect.size,
            colorSpace: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.last.rawValue)
        ).flatMap { image in
            ProcessedImage(image: image, imageRect: boundingRect)
        }
    }
}

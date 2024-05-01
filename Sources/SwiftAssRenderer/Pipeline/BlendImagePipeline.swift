import CoreGraphics
import SwiftLibass
import SwiftAssBlend

/// Pipeline that processed an `ASS_Image` into a ``ProcessedImage`` 
/// by alpha blending in place all the layers one by one.
public final class BlendImagePipeline: ImagePipelineType {
    public init() {}

    public func process(images: [ASS_Image], boundingRect: CGRect) -> ProcessedImage? {
        guard var image = images.first, !image.imageRect.size.isEmpty else { return nil }
        let blendResult = renderBlend(&image)

        return blendResult.buffer.flatMap { buffer in
            makeCGImage(
                buffer: UnsafeRawBufferPointer(start: buffer, count: Int(blendResult.buffer_size)),
                size: boundingRect.size,
                colorSpace: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.last.rawValue)
            )
        }.flatMap { image in
            ProcessedImage(image: image, imageRect: boundingRect)
        }
    }
}

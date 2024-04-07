import CoreGraphics
import SwiftLibass
import SwiftAssBlend

/// Pipeline that processed an ``ASS_Image`` into a ``ProcessedImage`` 
/// by alpha blending in place all the layers one by one.
public final class BlendImagePipeline: ImagePipelineType {
    public init() {}

    public func process(image: ASS_Image?) -> ProcessedImage? {
        guard var image, image.bitmap != nil else { return nil }
        let blendResult = renderBlend(&image)
        guard blendResult.buffer != nil else { return nil }

        let boundingRect = CGRect(
            x: Int(blendResult.bounding_rect_x),
            y: Int(blendResult.bounding_rect_y),
            width: Int(blendResult.bounding_rect_w),
            height: Int(blendResult.bounding_rect_h)
        )

        return makeCGImage(buffer: blendResult.buffer,
                           size: boundingRect.size,
                           colorSpace: CGColorSpaceCreateDeviceRGB(),
                           bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.last.rawValue)).flatMap { image in
            ProcessedImage(image: image, imageRect: boundingRect)
        }
    }
}

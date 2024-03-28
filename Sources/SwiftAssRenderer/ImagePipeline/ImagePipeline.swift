import CoreGraphics
import SwiftLibass
import SwiftAssBlend

protocol ImagePipelineType {
    func process(image: ASS_Image?) -> ProcessedImage?
}

final class ImagePipeline: ImagePipelineType {
    func process(image: ASS_Image?) -> ProcessedImage? {
        guard var image, image.bitmap != nil else { return nil }
        let blendResult = renderBlend(&image)
        guard blendResult.buffer != nil else { return nil}

        let boundingRect = CGRect(
            x: Int(blendResult.bounding_rect_x),
            y: Int(blendResult.bounding_rect_y),
            width: Int(blendResult.bounding_rect_w),
            height: Int(blendResult.bounding_rect_h)
        )

        return CGDataProvider(
            dataInfo: nil,
            data: blendResult.buffer,
            size: 4 * Int(boundingRect.width) * Int(boundingRect.height),
            releaseData: { _, buffer, _ in buffer.deallocate() }
        ).flatMap { provider in
            CGImage(
                width: Int(boundingRect.width),
                height: Int(boundingRect.height),
                bitsPerComponent: 8,
                bitsPerPixel: 8 * 4,
                bytesPerRow: 4 * Int(boundingRect.width),
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.last.rawValue),
                provider: provider,
                decode: nil,
                shouldInterpolate: false,
                intent: .defaultIntent
            )
        }.flatMap { image in
            ProcessedImage(image: image, imageRect: boundingRect)
        }
    }
}

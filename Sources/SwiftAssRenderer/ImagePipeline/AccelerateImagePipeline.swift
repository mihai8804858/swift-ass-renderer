import Accelerate
import CoreGraphics
import SwiftLibass

/// Pipeline that processed an `ASS_Image` into a ``ProcessedImage``
/// by combining all images using `vImage.PixelBuffer`.
@available(iOS 16.0, tvOS 16.0, visionOS 1.0, macOS 13.0, macCatalyst 16.0, *)
public final class AccelerateImagePipeline: ImagePipelineType {
    public init() {}

    public func process(images: [ASS_Image], boundingRect: CGRect) -> ProcessedImage? {
        guard let cgImage = blendImages(images, boundingRect: boundingRect) else { return nil }
        return ProcessedImage(image: cgImage, imageRect: boundingRect)
    }

    // MARK: - Private

    private func blendImages(_ images: [ASS_Image], boundingRect: CGRect) -> CGImage? {
        guard let size = vImage.Size(exactly: boundingRect.size) else { return nil }
        let destinationBuffer = makePixelBuffer(size: size, fillColor: (0, 0, 0, 0))
        for image in images {
            translateImage(image, into: destinationBuffer, size: size, boundingRect: boundingRect)
        }

        return makeImage(from: destinationBuffer, alphaInfo: .first)
    }

    private func translateImage(
        _ image: ASS_Image,
        into destinationBuffer: vImage.PixelBuffer<vImage.Interleaved8x4>,
        size: vImage.Size,
        boundingRect: CGRect
    ) {
        guard let sourceBuffer = makePixelBuffer(from: image, size: size) else { return }
        let relativeRect = image.relativeImageRect(to: boundingRect)
        let transform = CGAffineTransform.identity.translatedBy(
            x: relativeRect.minX,
            y: -(relativeRect.minY - boundingRect.height + relativeRect.height)
        )
        sourceBuffer.transform(
            transform,
            backgroundColor: (0, 0, 0, 0),
            destination: destinationBuffer
        )
    }

    private func makePixelBuffer(
        from image: ASS_Image,
        size: vImage.Size
    ) -> vImage.PixelBuffer<vImage.Interleaved8x4>? {
        guard let bitmap = palettizedBitmapARGB(image),
              let bitmapAddress = bitmap.baseAddress else { return nil }
        return vImage.PixelBuffer(
            data: bitmapAddress,
            width: Int(image.w),
            height: Int(image.h),
            byteCountPerRow: 4 * Int(image.w),
            pixelFormat: vImage.Interleaved8x4.self
        )
    }

    private func makePixelBuffer(
        size: vImage.Size,
        fillColor: Pixel_8888
    ) -> vImage.PixelBuffer<vImage.Interleaved8x4> {
        let destinationBuffer = vImage.PixelBuffer(
            size: size,
            pixelFormat: vImage.Interleaved8x4.self
        )
        destinationBuffer.overwriteChannels(
            [0, 1, 2, 3],
            withPixel: fillColor,
            destination: destinationBuffer
        )

        return destinationBuffer
    }

    private func makeImage(
        from buffer: vImage.PixelBuffer<vImage.Interleaved8x4>,
        alphaInfo: CGImageAlphaInfo
    ) -> CGImage? {
        vImage_CGImageFormat(
            bitsPerComponent: 8,
            bitsPerPixel: 8 * 4,
            colorSpace: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGBitmapInfo(rawValue: alphaInfo.rawValue)
        ).flatMap { format in
            buffer.makeCGImage(cgImageFormat: format)
        }
    }
}

private extension ASS_Image {
    func imageRect() -> CGRect {
        let origin = CGPoint(x: Int(dst_x), y: Int(dst_y))
        let size = CGSize(width: Int(w), height: Int(h))

        return CGRect(origin: origin, size: size)
    }

    func relativeImageRect(to boundingRect: CGRect) -> CGRect {
        let rect = imageRect()
        let origin = CGPoint(x: rect.minX - boundingRect.minX, y: rect.minY - boundingRect.minY)

        return CGRect(origin: origin, size: rect.size)
    }
}

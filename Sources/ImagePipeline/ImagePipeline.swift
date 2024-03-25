import Accelerate
import CoreGraphics
import SwiftLibass

protocol ImagePipelineType {
    func process(image: ASS_Image) -> ProcessedImage?
}

struct ImagePipeline: ImagePipelineType {
    func process(image: ASS_Image) -> ProcessedImage? {
        let images = linkedImages(from: image)
        if images.isEmpty { return nil }

        return process(images)
    }

    // MARK: - Private

    private func linkedImages(from image: ASS_Image) -> [ASS_Image] {
        var allImages: [ASS_Image] = []
        var currentImage: ASS_Image? = image
        while let image = currentImage {
            allImages.append(image)
            currentImage = image.next?.pointee
        }

        return allImages
    }

    private func palettizedBitmap(_ image: ASS_Image) -> [UInt8]? {
        if image.w == 0 || image.h == 0 { return nil }

        let width = Int(image.w)
        let height = Int(image.h)
        let stride = Int(image.stride)

        let red = UInt8((image.color >> 24) & 0xFF)
        let green = UInt8((image.color >> 16) & 0xFF)
        let blue = UInt8((image.color >> 8)  & 0xFF)
        let alpha = 255 - UInt8(image.color & 0xFF)

        let bufferCapacity = 4 * width * height
        let buffer = UnsafeMutableBufferPointer<UInt8>.allocate(capacity: bufferCapacity)
        buffer.initialize(repeating: 0)
        defer { buffer.deallocate() }

        var bufferPosition = 0
        var bitmapPosition = 0

        for _ in 0..<height {
            for xPosition in 0..<width {
                let alphaValue = image.bitmap.advanced(by: bitmapPosition + xPosition).pointee
                let normalizedAlpha = Int(alphaValue) * Int(alpha) / 255
                buffer[bufferPosition + 0] = red
                buffer[bufferPosition + 1] = green
                buffer[bufferPosition + 2] = blue
                buffer[bufferPosition + 3] = UInt8(normalizedAlpha)
                bufferPosition += 4

            }
            bitmapPosition += stride
        }

        return Array(buffer)
    }

    // swiftlint:disable:next function_body_length
    private func process(_ images: [ASS_Image]) -> ProcessedImage? {
        let minCast: Float = 0.9 / 255
        let maxCast: Float = 255.9 / 255

        func clamp(_ value: Float) -> UInt32 {
            value > minCast ? value < maxCast ? UInt32(value * 255) : 255 : 0
        }

        let boundingRect = images.map(\.rect).boundingRect
        if images.isEmpty || boundingRect.isEmpty { return nil }

        let bufferCapacity = 4 * Int(boundingRect.width) * Int(boundingRect.height)
        let buffer = UnsafeMutableBufferPointer<Float>.allocate(capacity: bufferCapacity)
        buffer.initialize(repeating: 0)
        defer { buffer.deallocate() }

        for image in images {
            let imageWidth = Int(image.w)
            let imageHeight = Int(image.h)
            let imageX = Int(image.dst_x) - Int(boundingRect.minX)
            let imageY = Int(image.dst_y) - Int(boundingRect.minY)
            let stride = Int(image.stride) >= imageWidth ? Int(image.stride) : imageWidth
            let alpha = 255 - Int(image.color & 0xFF)
            if imageWidth == 0 || imageHeight == 0 || alpha == 0 { continue }

            let normalizedAlpha = Float(alpha) / 255
            let red = Float((image.color >> 24) & 0xFF) / 255
            let green = Float((image.color >> 16) & 0xFF) / 255
            let blue = Float((image.color >> 8)  & 0xFF) / 255

            var lineStart = imageY * Int(boundingRect.width)
            var bitmapStart = 0
            for _ in 0..<imageHeight {
                for xPosition in 0..<imageWidth {
                    let pixelAlpha = Float(image.bitmap[bitmapStart + xPosition]) * normalizedAlpha / 255
                    let invAlpha = 1 - pixelAlpha
                    let bufferCoordinate = (lineStart + imageX + xPosition) << 2
                    buffer[bufferCoordinate + 0] = red * pixelAlpha   + buffer[bufferCoordinate + 0] * invAlpha
                    buffer[bufferCoordinate + 1] = green * pixelAlpha + buffer[bufferCoordinate + 1] * invAlpha
                    buffer[bufferCoordinate + 2] = blue * pixelAlpha  + buffer[bufferCoordinate + 2] * invAlpha
                    buffer[bufferCoordinate + 3] = pixelAlpha         + buffer[bufferCoordinate + 3] * invAlpha
                }
                bitmapStart += Int(stride)
                lineStart += Int(boundingRect.width)
            }
        }

        var lineStart = 0
        let pixelBuffer = unsafeBitCast(buffer, to: UnsafeMutableBufferPointer<UInt32>.self)
        for _ in 0..<Int(boundingRect.height) {
            for xPosition in 0..<Int(boundingRect.width) {
                var pixel: UInt32 = 0
                let bufferCoordinate = (lineStart + xPosition) << 2
                let alpha = buffer[bufferCoordinate + 3]
                if alpha > minCast {
                    var value = buffer[bufferCoordinate + 0] / alpha
                    pixel |= clamp(value)
                    value = buffer[bufferCoordinate + 1] / alpha
                    pixel |= clamp(value) << 8
                    value = buffer[bufferCoordinate + 2] / alpha
                    pixel |= clamp(value) << 16
                    pixel |= clamp(alpha) << 24
                }
                pixelBuffer[lineStart + xPosition] = pixel
            }
            lineStart += Int(boundingRect.width)
        }

        var finalBitmap = pixelBuffer.withMemoryRebound(to: UInt8.self) { Array($0) }
        let finalImagePixelBuffer = vImage.PixelBuffer<vImage.Interleaved8x4>(
            data: &finalBitmap,
            width: Int(boundingRect.width),
            height: Int(boundingRect.height),
            byteCountPerRow: 4 * Int(boundingRect.width)
        )

        return vImage_CGImageFormat(
            bitsPerComponent: 8,
            bitsPerPixel: 8 * 4,
            colorSpace: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.last.rawValue)
        ).flatMap { imageFormat in
            finalImagePixelBuffer
                .makeCGImage(cgImageFormat: imageFormat)
                .flatMap { ProcessedImage(image: $0, imageRect: boundingRect) }
        }
    }
}

private extension ASS_Image {
    var rect: CGRect {
        CGRect(x: CGFloat(dst_x), y: CGFloat(dst_y), width: CGFloat(w), height: CGFloat(h))
    }
}

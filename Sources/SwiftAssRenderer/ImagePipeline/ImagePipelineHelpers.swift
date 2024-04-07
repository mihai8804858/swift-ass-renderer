import CoreGraphics
import SwiftLibass

public extension ImagePipelineType {
    /// Find all the linked images from an `ASS_Image`.
    ///
    /// - Parameters:
    ///   - image: First image from the list.
    ///
    /// - Returns: A  list of `ASS_Image` that should be combined to produce 
    /// a final image ready to be drawn on the screen.
    func linkedImages(from image: ASS_Image) -> [ASS_Image] {
        var allImages: [ASS_Image] = []
        var currentImage: ASS_Image? = image
        while let image = currentImage {
            allImages.append(image)
            currentImage = image.next?.pointee
        }

        return allImages
    }

    /// Find the bounding rect of all linked images.
    ///
    /// - Parameters:
    ///   - image: First image from the list.
    ///
    /// - Returns: A `CGRect` containing all image rectangles.
    func boundingRect(image: ASS_Image) -> CGRect {
        let images = linkedImages(from: image)
        let imagesRect = images.map { image in
            CGRect(
                x: CGFloat(image.dst_x),
                y: CGFloat(image.dst_y),
                width: CGFloat(image.w),
                height: CGFloat(image.h)
            )
        }
        guard let minX = imagesRect.map(\.minX).min(),
              let minY = imagesRect.map(\.minY).min(),
              let maxX = imagesRect.map(\.maxX).max(),
              let maxY = imagesRect.map(\.maxY).max() else { return .zero }

        return CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
    }

    /// Creates an RGBA bytes buffer from an `ASS_Image`.
    ///
    /// - Parameters:
    ///   - image: The image to process.
    ///
    /// - Returns: A  new RGBA bytes buffer based on the `ASS_Image` bitmap.
    ///
    /// The `ASS_Image` only contains a monochrome alpha channel bitmap and a color.
    /// In order to combine all images and produce a palettized image, first all monochrome bitmaps
    /// need to be converted into palettized RGBA bitmaps, and then combined into a
    /// final RGBA image by alpha blending the images one by one.
    func palettizedBitmap(_ image: ASS_Image) -> UnsafeMutableBufferPointer<UInt8>? {
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

        var bufferPosition = 0
        var bitmapPosition = 0

        loop(iterations: height) { _ in
            loop(iterations: width) { xPosition in
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

        return buffer
    }

    /// Creates a `CGImage` from an RGBA buffer of bytes.
    ///
    /// - Parameters:
    ///   - buffer: RGBA bytes buffer.
    ///   - size: Image size.
    ///   - colorSpace: The color space for the image.
    ///   - bitmapInfo: A constant that specifies whether the bitmap should contain
    ///   an alpha channel and its relative location in a pixel,
    ///   along with whether the components are floating-point or integer values..
    ///
    /// - Returns: A  new `CGImage` created from the bytes buffer.
    ///
    /// The `CGImage` will hold onto the `buffer` and deallocate it when it won't be needing it anymore.
    func makeCGImage(
        buffer: UnsafeMutablePointer<UInt8>,
        size: CGSize,
        colorSpace: CGColorSpace,
        bitmapInfo: CGBitmapInfo
    ) -> CGImage? {
        CGDataProvider(
            dataInfo: nil,
            data: buffer,
            size: 4 * Int(size.width) * Int(size.height),
            releaseData: { _, buffer, _ in buffer.deallocate() }
        ).flatMap { provider in
            CGImage(
                width: Int(size.width),
                height: Int(size.height),
                bitsPerComponent: 8,
                bitsPerPixel: 8 * 4,
                bytesPerRow: 4 * Int(size.width),
                space: colorSpace,
                bitmapInfo: bitmapInfo,
                provider: provider,
                decode: nil,
                shouldInterpolate: false,
                intent: .defaultIntent
            )
        }
    }
}

// This is more performant than for in loop 🤷‍♂️
private func loop(iterations: Int, body: (Int) -> Void) {
    var index = 0
    while index < iterations {
        body(index)
        index += 1
    }
}

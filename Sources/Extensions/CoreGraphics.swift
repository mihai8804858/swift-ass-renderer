import CoreGraphics

extension CGPoint {
    func rounded() -> CGPoint {
        CGPoint(x: x.rounded(.toNearestOrAwayFromZero), y: y.rounded(.toNearestOrAwayFromZero))
    }
}

extension CGSize {
    func rounded() -> CGSize {
        CGSize(width: width.rounded(.toNearestOrAwayFromZero), height: height.rounded(.toNearestOrAwayFromZero))
    }

    static func * (lhs: CGSize, rhs: CGFloat) -> CGSize {
        CGSize(width: lhs.width * rhs, height: lhs.height * rhs)
    }

    static func / (lhs: CGSize, rhs: CGFloat) -> CGSize {
        CGSize(width: lhs.width / rhs, height: lhs.height / rhs)
    }
}

extension CGRect {
    func rounded() -> CGRect {
        CGRect(origin: origin.rounded(), size: size.rounded())
    }

    static func / (lhs: CGRect, rhs: CGFloat) -> CGRect {
        CGRect(x: lhs.origin.x / rhs, y: lhs.origin.y / rhs, width: lhs.width / rhs, height: lhs.height / rhs)
    }
}

extension [CGRect] {
    var boundingRect: CGRect {
        guard let minX = map(\.minX).min(),
              let minY = map(\.minY).min(),
              let maxX = map(\.maxX).max(),
              let maxY = map(\.maxY).max() else { return .zero }

        return CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
    }
}

extension CGImage {
    static func fromInterleaved8x4Bitmap(_ bitmap: inout [UInt8], size: CGSize, alpha: CGImageAlphaInfo) -> CGImage? {
        guard let dataInfo = CGDataProvider(
            dataInfo: nil,
            data: &bitmap,
            size: bitmap.count,
            releaseData: { _, _, _ in }
        ) else { return nil }

        return CGImage(
            width: Int(size.width),
            height: Int(size.height),
            bitsPerComponent: 8,
            bitsPerPixel: 8 * 4,
            bytesPerRow: 4 * Int(size.width),
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGBitmapInfo(rawValue: alpha.rawValue),
            provider: dataInfo,
            decode: nil,
            shouldInterpolate: false,
            intent: .defaultIntent
        )
    }
}

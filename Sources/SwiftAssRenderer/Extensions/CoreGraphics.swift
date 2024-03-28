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

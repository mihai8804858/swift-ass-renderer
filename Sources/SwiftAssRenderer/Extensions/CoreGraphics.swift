import CoreGraphics

extension CGSize {
    var isEmpty: Bool {
        width == 0 || height == 0
    }

    static func * (lhs: CGSize, rhs: CGFloat) -> CGSize {
        CGSize(width: lhs.width * rhs, height: lhs.height * rhs)
    }

    static func / (lhs: CGSize, rhs: CGFloat) -> CGSize {
        CGSize(width: lhs.width / rhs, height: lhs.height / rhs)
    }
}

extension CGRect {
    static func / (lhs: CGRect, rhs: CGFloat) -> CGRect {
        CGRect(x: lhs.origin.x / rhs, y: lhs.origin.y / rhs, width: lhs.width / rhs, height: lhs.height / rhs)
    }

    func flippingY(for height: CGFloat) -> CGRect {
        CGRect(origin: CGPoint(x: origin.x, y: -(origin.y - height + size.height)), size: size)
    }
}

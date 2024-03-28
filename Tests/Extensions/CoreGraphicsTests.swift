import XCTest
@testable import SwiftAssRenderer

final class CoreGraphicsTests: XCTestCase {
    func testCGPoint_rounded_shouldRound() {
        // GIVEN
        let point = CGPoint(x: 1.2, y: 3.6)

        // WHEN
        let roundedPoint = point.rounded()

        // THEN
        XCTAssertEqual(roundedPoint, CGPoint(x: 1, y: 4))
    }

    func testCGSize_rounded_shouldRound() {
        // GIVEN
        let size = CGSize(width: 1.2, height: 3.6)

        // WHEN
        let roundedSize = size.rounded()

        // THEN
        XCTAssertEqual(roundedSize, CGSize(width: 1, height: 4))
    }

    func testCGSize_multiplied_shouldMultiply() {
        // GIVEN
        let size = CGSize(width: 100, height: 200)

        // WHEN
        let multipliedSize = size * 3

        // THEN
        let expectedSize = CGSize(width: 300, height: 600)
        XCTAssertEqual(multipliedSize, expectedSize)
    }

    func testCGSize_divided_shouldDivide() {
        // GIVEN
        let size = CGSize(width: 100, height: 200)

        // WHEN
        let dividedSize = size / 2

        // THEN
        let expectedSize = CGSize(width: 50, height: 100)
        XCTAssertEqual(dividedSize, expectedSize)
    }

    func testCGRect_rounded_shouldRound() {
        // GIVEN
        let rect = CGRect(origin: CGPoint(x: 1.2, y: 3.6), size: CGSize(width: 4.5, height: 7.9))

        // WHEN
        let roundedRect = rect.rounded()

        // THEN
        let expectedRect = CGRect(origin: CGPoint(x: 1, y: 4), size: CGSize(width: 5, height: 8))
        XCTAssertEqual(roundedRect, expectedRect)
    }

    func testCGRect_divided_shouldDivide() {
        // GIVEN
        let rect = CGRect(origin: CGPoint(x: 100, y: 200), size: CGSize(width: 300, height: 400))

        // WHEN
        let dividedRect = rect / 2

        // THEN
        let expectedRect = CGRect(origin: CGPoint(x: 50, y: 100), size: CGSize(width: 150, height: 200))
        XCTAssertEqual(dividedRect, expectedRect)
    }
}

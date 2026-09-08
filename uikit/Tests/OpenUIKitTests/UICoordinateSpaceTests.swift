import XCTest
import Foundation
@testable import OpenUIKit

#if !os(Linux)
@MainActor
#endif
private final class SentinelCoordinateSpace: NSObject, UICoordinateSpace {
    let bounds = CGRect(x: 1, y: 2, width: 300, height: 400)
    var calls = 0
    func convert(_ point: CGPoint, to coordinateSpace: UICoordinateSpace) -> CGPoint {
        calls += 1
        return CGPoint(x: 101, y: 102)
    }
    func convert(_ point: CGPoint, from coordinateSpace: UICoordinateSpace) -> CGPoint {
        calls += 1
        return CGPoint(x: 201, y: 202)
    }
    func convert(_ rect: CGRect, to coordinateSpace: UICoordinateSpace) -> CGRect {
        calls += 1
        return CGRect(x: 301, y: 302, width: 303, height: 304)
    }
    func convert(_ rect: CGRect, from coordinateSpace: UICoordinateSpace) -> CGRect {
        calls += 1
        return CGRect(x: 401, y: 402, width: 403, height: 404)
    }
}

#if !os(Linux)
@MainActor
#endif
final class UICoordinateSpaceTests: XCTestCase {
    // Same bounds-offset hierarchy and inputs as CoordinateSpaceProbe on
    // iOS 26.1 SE 2x (Tools/oracle2/coordinatespaceprobe/ios-26.1.txt).
    private func hierarchy() -> (UIView, UIView, UIView) {
        let root = UIView(frame: CGRect(x: 0, y: 0, width: 375, height: 667))
        let parent = UIView(frame: CGRect(x: 40, y: 60, width: 200, height: 300))
        let child = UIView(frame: CGRect(x: 10, y: 20, width: 80, height: 100))
        let sibling = UIView(frame: CGRect(x: 150, y: 220, width: 100, height: 100))
        root.addSubview(parent)
        parent.addSubview(child)
        root.addSubview(sibling)
        child.bounds.origin = CGPoint(x: 3, y: 4)
        return (root, child, sibling)
    }

    func testBoundsAndIdentityThroughProtocol() {
        let (root, child, _) = hierarchy()
        withExtendedLifetime(root) {
            let space: UICoordinateSpace = child
            XCTAssertEqual(space.bounds, CGRect(x: 3, y: 4, width: 80, height: 100))
            XCTAssertEqual(space.convert(CGPoint(x: 8, y: 9), to: space), CGPoint(x: 8, y: 9))
            let rect = CGRect(x: 8, y: 9, width: 30, height: 40)
            XCTAssertEqual(space.convert(rect, from: space), rect)
            XCTAssertTrue(space.isEqual(child))
        }
    }

    func testPointConversionsThroughProtocol() {
        let (root, child, sibling) = hierarchy()
        withExtendedLifetime(root) {
            let a: UICoordinateSpace = child
            let b: UICoordinateSpace = sibling
            let point = CGPoint(x: 8, y: 9)
            XCTAssertEqual(a.convert(point, to: b), CGPoint(x: -95, y: -135))
            XCTAssertEqual(a.convert(point, from: b), CGPoint(x: 111, y: 153))
        }
    }

    func testRectConversionsThroughProtocol() {
        let (root, child, sibling) = hierarchy()
        withExtendedLifetime(root) {
            let a: UICoordinateSpace = child
            let b: UICoordinateSpace = sibling
            let rect = CGRect(x: 8, y: 9, width: 30, height: 40)
            XCTAssertEqual(a.convert(rect, to: b), CGRect(x: -95, y: -135, width: 30, height: 40))
            XCTAssertEqual(a.convert(rect, from: b), CGRect(x: 111, y: 153, width: 30, height: 40))
        }
    }

    func testUnknownCoordinateSpaceUsesRootWithoutForwarding() {
        let (root, child, _) = hierarchy()
        withExtendedLifetime(root) {
            let view: UICoordinateSpace = child
            let custom = SentinelCoordinateSpace()
            let point = CGPoint(x: 8, y: 9)
            let rect = CGRect(x: 8, y: 9, width: 30, height: 40)
            XCTAssertEqual(view.convert(point, to: custom), CGPoint(x: 55, y: 85))
            XCTAssertEqual(view.convert(point, from: custom), CGPoint(x: -39, y: -67))
            XCTAssertEqual(view.convert(rect, to: custom), CGRect(x: 55, y: 85, width: 30, height: 40))
            XCTAssertEqual(view.convert(rect, from: custom), CGRect(x: -39, y: -67, width: 30, height: 40))
            XCTAssertEqual(custom.calls, 0)
        }
    }

    func testTransformedRectUsesAxisAlignedBounds() {
        let (root, child, sibling) = hierarchy()
        withExtendedLifetime(root) {
            child.transform = OpenUIKit.CGAffineTransform(rotationAngle: .pi / 2)
            let a: UICoordinateSpace = child
            let b: UICoordinateSpace = sibling
            let point = a.convert(CGPoint(x: 8, y: 9), to: b)
            XCTAssertEqual(point.x, -15, accuracy: 1e-9)
            XCTAssertEqual(point.y, -125, accuracy: 1e-9)
            let rect = CGRect(x: 8, y: 9, width: 30, height: 40)
            let to = a.convert(rect, to: b)
            XCTAssertEqual(to.minX, -55, accuracy: 1e-9)
            XCTAssertEqual(to.minY, -125, accuracy: 1e-9)
            XCTAssertEqual(to.width, 40, accuracy: 1e-9)
            XCTAssertEqual(to.height, 30, accuracy: 1e-9)
            let from = a.convert(rect, from: b)
            XCTAssertEqual(from.minX, 142, accuracy: 1e-9)
            XCTAssertEqual(from.minY, -44, accuracy: 1e-9)
            XCTAssertEqual(from.width, 40, accuracy: 1e-9)
            XCTAssertEqual(from.height, 30, accuracy: 1e-9)
        }
    }
}

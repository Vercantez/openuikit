import XCTest
import Foundation
@testable import OpenUIKit

// UIScreen.coordinateSpace / fixedCoordinateSpace and cross-window
// conversion, measured by Tools/oracle2/signalrowsprobe (iPhone 16 / iOS
// 26.1, `screen.*` in ios-26.1-iphone16.json). Same hierarchy and inputs as
// the probe: a full-screen window, parent (40, 60, 200, 300), child
// (10, 20, 80, 100) with bounds origin (3, 4), point (8, 9), rect
// (8, 9, 30, 40).

#if !os(Linux)
@MainActor
#endif
final class UIScreenCoordinateSpaceTests: XCTestCase {
    private let point = CGPoint(x: 8, y: 9)
    private let rect = CGRect(x: 8, y: 9, width: 30, height: 40)

    /// Windows built by `hierarchy()`; the tuple's window would otherwise be
    /// released before the child converts, leaving it a detached root.
    private var retained: [UIWindow] = []

    private func hierarchy() -> (UIWindow, UIView) {
        let window = UIWindow(frame: UIScreen.main.bounds)
        retained.append(window)
        let parent = UIView(frame: CGRect(x: 40, y: 60, width: 200, height: 300))
        let child = UIView(frame: CGRect(x: 10, y: 20, width: 80, height: 100))
        window.addSubview(parent)
        parent.addSubview(child)
        child.bounds.origin = CGPoint(x: 3, y: 4)
        return (window, child)
    }

    private func assertEqual(_ a: CGRect, _ b: CGRect, file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertEqual(a.origin.x, b.origin.x, accuracy: 1e-9, file: file, line: line)
        XCTAssertEqual(a.origin.y, b.origin.y, accuracy: 1e-9, file: file, line: line)
        XCTAssertEqual(a.width, b.width, accuracy: 1e-9, file: file, line: line)
        XCTAssertEqual(a.height, b.height, accuracy: 1e-9, file: file, line: line)
    }

    func testScreenSpaceIsTheScreenAndFixedSpaceIsDistinct() {
        let screen = UIScreen.main
        let space = screen.coordinateSpace
        let fixed = screen.fixedCoordinateSpace
        XCTAssertTrue(space === screen)
        XCTAssertTrue(space === screen.coordinateSpace)
        XCTAssertTrue(fixed === screen.fixedCoordinateSpace)
        XCTAssertFalse(space === fixed)
        XCTAssertFalse(space is UIView)
        XCTAssertTrue(type(of: fixed) == _UIScreenFixedCoordinateSpace.self)
        XCTAssertEqual(space.bounds, screen.bounds)
        XCTAssertEqual(fixed.bounds, screen.bounds)
        XCTAssertEqual(space.bounds.origin, .zero)
        let (window, _) = hierarchy()
        XCTAssertFalse((window as UICoordinateSpace) === space)
        XCTAssertEqual(window.convert(point, to: space), point)
        XCTAssertEqual(space.convert(point, to: fixed), point)
        XCTAssertEqual(fixed.convert(point, from: space), point)
    }

    func testNestedChildConvertsThroughTheScreenSpaceBothWays() {
        let (_, child) = hierarchy()
        let space = UIScreen.main.coordinateSpace
        XCTAssertEqual(child.convert(point, to: space), CGPoint(x: 55, y: 85))
        XCTAssertEqual(child.convert(point, from: space), CGPoint(x: -39, y: -67))
        XCTAssertEqual(child.convert(rect, to: space), CGRect(x: 55, y: 85, width: 30, height: 40))
        XCTAssertEqual(child.convert(rect, from: space), CGRect(x: -39, y: -67, width: 30, height: 40))
        XCTAssertEqual(space.convert(point, to: child), CGPoint(x: -39, y: -67))
        XCTAssertEqual(space.convert(point, from: child), CGPoint(x: 55, y: 85))
        XCTAssertEqual(space.convert(rect, to: child), CGRect(x: -39, y: -67, width: 30, height: 40))
        XCTAssertEqual(space.convert(rect, from: child), CGRect(x: 55, y: 85, width: 30, height: 40))
        let fixed = UIScreen.main.fixedCoordinateSpace
        XCTAssertEqual(child.convert(point, to: fixed), CGPoint(x: 55, y: 85))
        XCTAssertEqual(fixed.convert(point, to: child), CGPoint(x: -39, y: -67))
    }

    func testRotatedChildUsesAxisAlignedBoundsInScreenSpace() {
        let (_, child) = hierarchy()
        child.transform = CGAffineTransform(rotationAngle: .pi / 2)
        let space = UIScreen.main.coordinateSpace
        let to = child.convert(point, to: space)
        XCTAssertEqual(to.x, 135, accuracy: 1e-9)
        XCTAssertEqual(to.y, 95, accuracy: 1e-9)
        assertEqual(child.convert(rect, to: space), CGRect(x: 95, y: 95, width: 40, height: 30))
        assertEqual(child.convert(rect, from: space), CGRect(x: -78, y: 106, width: 40, height: 30))
        assertEqual(space.convert(rect, to: child), CGRect(x: -78, y: 106, width: 40, height: 30))
    }

    func testOffsetWindowAddsItsFrameOriginAndCrossWindowConversionUsesIt() {
        let (main, _) = hierarchy()
        let offset = UIWindow(frame: CGRect(x: 10, y: 20, width: 300, height: 400))
        retained.append(offset)
        let inner = UIView(frame: CGRect(x: 5, y: 6, width: 50, height: 50))
        offset.addSubview(inner)
        let space = UIScreen.main.coordinateSpace
        XCTAssertEqual(inner.convert(point, to: space), CGPoint(x: 23, y: 35))
        XCTAssertEqual(inner.convert(point, to: main), CGPoint(x: 23, y: 35))
        XCTAssertEqual(main.convert(point, from: inner), CGPoint(x: 23, y: 35))
        XCTAssertEqual(inner.convert(point, to: nil), CGPoint(x: 13, y: 15))
        XCTAssertEqual(space.convert(point, to: inner), CGPoint(x: -7, y: -17))
        XCTAssertEqual(inner.convert(rect, to: space), CGRect(x: 23, y: 35, width: 30, height: 40))
    }
}

import XCTest
@testable import OpenUIKit

final class GeometryTests: XCTestCase {
    func testRectIntersection() {
        let a = CGRect(x: 0, y: 0, width: 10, height: 10)
        let b = CGRect(x: 5, y: 5, width: 10, height: 10)
        XCTAssertEqual(a.intersection(b), CGRect(x: 5, y: 5, width: 5, height: 5))
    }
}

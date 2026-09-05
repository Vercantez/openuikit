#if os(Linux)
import XCTest
@testable import OpenUIKit

final class NSStringDrawingTests: XCTestCase {
    func testLineFragmentBoundingRectWrapsWithinMaximumWidth() {
        let text = "A portable tooltip sentence that needs multiple lines"
        let rect = text.boundingRect(
            with: CGSize(width: 70, height: CGFloat.greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin],
            context: nil
        )

        XCTAssertGreaterThan(rect.height, UIFont.systemFont(ofSize: 12).lineHeight)
        XCTAssertLessThanOrEqual(rect.width, 70)
        XCTAssertEqual(rect.origin, CGPoint.zero)
    }
}
#endif

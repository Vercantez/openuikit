import XCTest
import OpenUIKit
@testable import SwiftUI

final class SwiftUIStrokeStyleTests: XCTestCase {
    func testAppleShapedDefaults() {
        let style = StrokeStyle()
        XCTAssertEqual(style.lineWidth, 1)
        assertLineCap(style.lineCap, is: .butt)
        assertLineJoin(style.lineJoin, is: .miter)
        XCTAssertEqual(style.miterLimit, 10)
        XCTAssertEqual(style.dash, [])
        XCTAssertEqual(style.dashPhase, 0)
    }

    func testStrokePolicyIsRetainedAsHashableSendableValue() async {
        let style = StrokeStyle(
            lineWidth: 2.5,
            lineCap: .round,
            lineJoin: .bevel,
            miterLimit: 7,
            dash: [4, 2, 1],
            dashPhase: 3
        )
        let copied = await Task.detached { style }.value

        XCTAssertEqual(copied, style)
        XCTAssertEqual(Set([style, copied]).count, 1)
        XCTAssertEqual(copied.lineWidth, 2.5)
        assertLineCap(copied.lineCap, is: .round)
        assertLineJoin(copied.lineJoin, is: .bevel)
        XCTAssertEqual(copied.miterLimit, 7)
        XCTAssertEqual(copied.dash, [4, 2, 1])
        XCTAssertEqual(copied.dashPhase, 3)

        var changed = copied
        changed.dashPhase = 4
        XCTAssertNotEqual(changed, style)
    }

    private func assertLineCap(
        _ actual: OpenUIKit.CGLineCap,
        is expected: OpenUIKit.CGLineCap,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let actualCode: UInt8
        let expectedCode: UInt8
        switch actual { case .butt: actualCode = 0; case .round: actualCode = 1; case .square: actualCode = 2 }
        switch expected { case .butt: expectedCode = 0; case .round: expectedCode = 1; case .square: expectedCode = 2 }
        XCTAssertEqual(actualCode, expectedCode, file: file, line: line)
    }

    private func assertLineJoin(
        _ actual: OpenUIKit.CGLineJoin,
        is expected: OpenUIKit.CGLineJoin,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let actualCode: UInt8
        let expectedCode: UInt8
        switch actual { case .miter: actualCode = 0; case .round: actualCode = 1; case .bevel: actualCode = 2 }
        switch expected { case .miter: expectedCode = 0; case .round: expectedCode = 1; case .bevel: expectedCode = 2 }
        XCTAssertEqual(actualCode, expectedCode, file: file, line: line)
    }
}

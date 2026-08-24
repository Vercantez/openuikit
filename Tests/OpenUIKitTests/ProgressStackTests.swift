// Tests for the controls (UIProgressView) + stack (UIStackView) modules.
// Expected values are oracle-verified (Mac Catalyst iOS 26.1 UIKit):
// golden/progress_views.layout.json, golden/stack_{horizontal,vertical}
// .layout.json plus fillEqually probes at scales 1/2/3.

import XCTest
@testable import OpenUIKit

// XCTest re-exports Foundation/CoreGraphics on Darwin; pin the portable types.
private typealias CGFloat = OpenUIKit.CGFloat
private typealias CGPoint = OpenUIKit.CGPoint
private typealias CGSize = OpenUIKit.CGSize
private typealias CGRect = OpenUIKit.CGRect

final class ProgressViewTests: XCTestCase {
    func testIntrinsicSize() {
        let p = UIProgressView()
        XCTAssertEqual(p.intrinsicContentSize.width, UIView.noIntrinsicMetric)
        XCTAssertEqual(p.intrinsicContentSize.height, 4)
    }

    func testHeightForcedTo4PreservingOrigin() {
        let p = UIProgressView(frame: CGRect(x: 20, y: 140, width: 280, height: 10))
        p.layoutSubviews()
        XCTAssertEqual(p.frame, CGRect(x: 20, y: 140, width: 280, height: 4))
    }

    func testProgressClamped() {
        let p = UIProgressView()
        p.progress = 1.5
        XCTAssertEqual(p.progress, 1)
        p.progress = -0.5
        XCTAssertEqual(p.progress, 0)
    }

    func testFillWidthRounding() {
        // Oracle: fill width = round-half-up(progress * width), min 8pt.
        let p = UIProgressView(frame: CGRect(x: 0, y: 0, width: 280, height: 4))
        p.progress = 0.3
        XCTAssertEqual(p.fillWidth, 84)     // exact
        p.progress = 0.333
        XCTAssertEqual(p.fillWidth, 93)     // 93.24 -> 93
        p.progress = 0.01
        XCTAssertEqual(p.fillWidth, 8)      // 2.8 -> min 8
        p.progress = 1
        XCTAssertEqual(p.fillWidth, 280)

        let q = UIProgressView(frame: CGRect(x: 0, y: 0, width: 281, height: 4))
        q.progress = 0.5
        XCTAssertEqual(q.fillWidth, 141)    // 140.5 -> half-up -> 141
    }
}

final class StackViewTests: XCTestCase {
    // Disambiguate from AppKit/Foundation NSLayoutConstraint on Darwin.
    private typealias Axis = OpenUIKit.NSLayoutConstraint.Axis

    private func makeStack(axis: Axis, frame: CGRect,
                           spacing: CGFloat, count: Int,
                           distribution: UIStackView.Distribution = .fillEqually)
        -> (UIStackView, [UIView]) {
        let s = UIStackView(frame: frame)
        s.axis = axis
        s.spacing = spacing
        s.distribution = distribution
        var children: [UIView] = []
        for _ in 0..<count {
            let v = UIView()
            s.addArrangedSubview(v)
            children.append(v)
        }
        return (s, children)
    }

    func testFillEquallyHorizontalExactSplit() {
        // golden/stack_horizontal: (320 - 3*8) / 4 = 74 exact.
        let (s, c) = makeStack(axis: .horizontal,
                               frame: CGRect(x: 10, y: 10, width: 320, height: 100),
                               spacing: 8, count: 4)
        s.layoutSubviews()
        XCTAssertEqual(c.map { $0.frame.origin.x }, [0, 82, 164, 246])
        XCTAssertEqual(c.map { $0.frame.width }, [74, 74, 74, 74])
        XCTAssertEqual(c.map { $0.frame.height }, [100, 100, 100, 100])  // alignment .fill
    }

    func testFillEquallyVerticalFractionalRounding() {
        // golden/stack_vertical: (300 - 20) / 3 = 93.333 -> size 93.5,
        // origins 0 / 103 / 207 (size to nearest 0.5, origin to nearest 1,
        // both half-up; last view overhangs bounds by 0.5).
        let (s, c) = makeStack(axis: .vertical,
                               frame: CGRect(x: 10, y: 10, width: 180, height: 300),
                               spacing: 10, count: 3)
        s.layoutSubviews()
        XCTAssertEqual(c.map { $0.frame.origin.y }, [0, 103, 207])
        XCTAssertEqual(c.map { $0.frame.height }, [93.5, 93.5, 93.5])
        XCTAssertEqual(c.map { $0.frame.width }, [180, 180, 180])
    }

    func testFillEquallyTieRounding() {
        // Oracle probe pv_99_4_0: 99/4 = 24.75 -> size 25 (49.5px half-up);
        // origins 24.75 -> 25, 49.5 -> 50 (half-up, NOT half-even), 74.25 -> 74.
        let (s, c) = makeStack(axis: .vertical,
                               frame: CGRect(x: 0, y: 0, width: 100, height: 99),
                               spacing: 0, count: 4)
        s.layoutSubviews()
        XCTAssertEqual(c.map { $0.frame.origin.y }, [0, 25, 50, 74])
        XCTAssertEqual(c.map { $0.frame.height }, [25, 25, 25, 25])
    }

    func testFillEquallySeventhsRounding() {
        // Oracle probe ph_99_7_2: (99 - 12) / 7 = 12.4286 -> 12.5;
        // origins 14.43->14, 28.86->29, 43.29->43, 57.71->58, 72.14->72, 86.57->87.
        let (s, c) = makeStack(axis: .horizontal,
                               frame: CGRect(x: 0, y: 0, width: 99, height: 50),
                               spacing: 2, count: 7)
        s.layoutSubviews()
        XCTAssertEqual(c.map { $0.frame.origin.x }, [0, 14, 29, 43, 58, 72, 87])
        XCTAssertEqual(c.map { $0.frame.width }, Array(repeating: 12.5, count: 7))
    }

    func testHiddenArrangedViewCollapses() {
        // Oracle probe ph_hid_320_4_8: 4 views, spacing 8, index 2 hidden ->
        // remaining three get (320-16)/3 = 101.333 -> 101.5 at x 0/109/219;
        // the hidden view parks zero-width at round(218.667 - 4) = 215,
        // full cross size (alignment .fill).
        let (s, c) = makeStack(axis: .horizontal,
                               frame: CGRect(x: 10, y: 10, width: 320, height: 100),
                               spacing: 8, count: 4)
        c[2].isHidden = true
        s.layoutSubviews()
        XCTAssertEqual(c[0].frame, CGRect(x: 0, y: 0, width: 101.5, height: 100))
        XCTAssertEqual(c[1].frame, CGRect(x: 109, y: 0, width: 101.5, height: 100))
        XCTAssertEqual(c[2].frame, CGRect(x: 215, y: 0, width: 0, height: 100))
        XCTAssertEqual(c[3].frame, CGRect(x: 219, y: 0, width: 101.5, height: 100))
    }

    func testArrangedSubviewBookkeeping() {
        let s = UIStackView()
        let a = UIView(), b = UIView()
        s.addArrangedSubview(a)
        s.addArrangedSubview(b)
        XCTAssertTrue(s.arrangedSubviews[0] === a && s.arrangedSubviews[1] === b)
        XCTAssertEqual(s.subviews.count, 2)
        // removeArrangedSubview keeps the view in subviews (UIKit semantics).
        s.removeArrangedSubview(a)
        XCTAssertEqual(s.arrangedSubviews.count, 1)
        XCTAssertEqual(s.subviews.count, 2)
        // A view removed from the hierarchy stops being laid out.
        b.removeFromSuperview()
        s.bounds = CGRect(x: 0, y: 0, width: 100, height: 100)
        s.layoutSubviews()  // must not crash or resurrect b
        XCTAssertNil(b.superview)
    }
}

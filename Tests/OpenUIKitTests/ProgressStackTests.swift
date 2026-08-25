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

@MainActor
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

@MainActor
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

    /// Stand-in for a UILabel-like view with a fixed intrinsic size, so the
    /// .fill tests don't depend on font rendering.
    @MainActor
    private final class IntrinsicView: UIView {
        let size: CGSize
        init(_ w: CGFloat, _ h: CGFloat) {
            size = CGSize(width: w, height: h)
            super.init(frame: .zero)
        }
        override var intrinsicContentSize: CGSize { size }
        override func sizeThatFits(_ s: CGSize) -> CGSize { size }
    }

    private func makeFillStack(frame: CGRect, spacing: CGFloat,
                               alignment: UIStackView.Alignment = .fill) -> UIStackView {
        let s = UIStackView(frame: frame)
        s.axis = .horizontal
        s.spacing = spacing
        s.distribution = .fill
        s.alignment = alignment
        return s
    }

    func testFillSlackGoesToNoIntrinsicSpacerNotLastView() {
        // golden/stack_mixed path 1: [Left 28x19, plain UIView, Right 37.5x19]
        // in 300x30, spacing 8, alignment center -> the spacer stretches to
        // 218.5 and the trailing label keeps its intrinsic width at x 263
        // (262.5 rounded), y 6, NOT the last view absorbing the slack.
        let s = makeFillStack(frame: CGRect(x: 10, y: 10, width: 300, height: 30),
                              spacing: 8, alignment: .center)
        let left = IntrinsicView(28, 19), spacer = UIView(), right = IntrinsicView(37.5, 19)
        [left, spacer, right].forEach { s.addArrangedSubview($0) }
        s.layoutSubviews()
        XCTAssertEqual(left.frame, CGRect(x: 0, y: 6, width: 28, height: 19))
        XCTAssertEqual(spacer.frame, CGRect(x: 36, y: 15, width: 218.5, height: 0))
        XCTAssertEqual(right.frame, CGRect(x: 263, y: 6, width: 37.5, height: 19))
        // Second layout pass must be identical (measurement never reads the
        // spacer's stretched frame back as its content size).
        s.layoutSubviews()
        XCTAssertEqual(spacer.frame.width, 218.5)
        XCTAssertEqual(right.frame.origin.x, 263)
    }

    func testFillAllIntrinsicStretchesFirstView() {
        // Oracle probe probe_fill_labels: 29.5/29/41.5 in 300, spacing 8 ->
        // FIRST view stretched to 213.5; others at x 222 and 259.
        let s = makeFillStack(frame: CGRect(x: 10, y: 10, width: 300, height: 30),
                              spacing: 8)
        let a = IntrinsicView(29.5, 19), b = IntrinsicView(29, 19), c = IntrinsicView(41.5, 19)
        [a, b, c].forEach { s.addArrangedSubview($0) }
        s.layoutSubviews()
        XCTAssertEqual([a, b, c].map { $0.frame.origin.x }, [0, 222, 259])
        XCTAssertEqual([a, b, c].map { $0.frame.width }, [213.5, 29, 41.5])
    }

    func testFillAllIntrinsicCompressesFirstView() {
        // Oracle probe probe_fill_compress: 76.5/94 in 120, spacing 8 ->
        // FIRST view compressed to 18, second keeps 94 at x 26.
        let s = makeFillStack(frame: CGRect(x: 10, y: 10, width: 120, height: 30),
                              spacing: 8)
        let a = IntrinsicView(76.5, 19), b = IntrinsicView(94, 19)
        [a, b].forEach { s.addArrangedSubview($0) }
        s.layoutSubviews()
        XCTAssertEqual([a, b].map { $0.frame.origin.x }, [0, 26])
        XCTAssertEqual([a, b].map { $0.frame.width }, [18, 94])
    }

    func testFillTwoSpacersLastOneTakesAllSlack() {
        // Oracle probe probe_fill_twospacers: 29.5/spacer/29/spacer/41.5 in
        // 300, spacing 8 -> first spacer collapses to 0 at x 38, second
        // takes the whole 168pt slack at x 83.
        let s = makeFillStack(frame: CGRect(x: 10, y: 10, width: 300, height: 30),
                              spacing: 8)
        let a = IntrinsicView(29.5, 19), s1 = UIView(), b = IntrinsicView(29, 19)
        let s2 = UIView(), c = IntrinsicView(41.5, 19)
        [a, s1, b, s2, c].forEach { s.addArrangedSubview($0) }
        s.layoutSubviews()
        XCTAssertEqual([a, s1, b, s2, c].map { $0.frame.origin.x }, [0, 38, 46, 83, 259])
        XCTAssertEqual([a, s1, b, s2, c].map { $0.frame.width }, [29.5, 0, 29, 168, 41.5])
    }

    func testNestedStackFittingSizeAndTopAlignment() {
        // golden/label_stack_mix path 2.0: outer horizontal fillEqually
        // alignment-top stack (266x111, spacing 10) of two vertical .fill
        // stacks (spacing 3, children 39x19 / 34.5x16 / 28.5x16 like the
        // Col A labels) -> inner stacks measure a 57pt fitting height and
        // get frames [0,0,128,57] / [138,0,128,57].
        func innerStack() -> UIStackView {
            let v = UIStackView()
            v.axis = .vertical
            v.spacing = 3
            v.distribution = .fill
            v.alignment = .leading
            v.addArrangedSubview(IntrinsicView(39, 19))
            v.addArrangedSubview(IntrinsicView(34.5, 16))
            v.addArrangedSubview(IntrinsicView(28.5, 16))
            return v
        }
        let inner1 = innerStack(), inner2 = innerStack()
        XCTAssertEqual(inner1.sizeThatFits(CGSize(width: 266, height: 111)),
                       CGSize(width: 39, height: 57))
        let outer = UIStackView(frame: CGRect(x: 12, y: 12, width: 266, height: 111))
        outer.axis = .horizontal
        outer.spacing = 10
        outer.distribution = .fillEqually
        outer.alignment = .top
        outer.addArrangedSubview(inner1)
        outer.addArrangedSubview(inner2)
        outer.layoutSubviews()
        XCTAssertEqual(inner1.frame, CGRect(x: 0, y: 0, width: 128, height: 57))
        XCTAssertEqual(inner2.frame, CGRect(x: 138, y: 0, width: 128, height: 57))
        // And the inner stack lays its children out inside that 57pt with
        // zero slack: 19/16/16 at y 0/22/41 (golden paths 2.0.0.*).
        inner1.layoutSubviews()
        XCTAssertEqual(inner1.subviews.map { $0.frame.origin.y }, [0, 22, 41])
        XCTAssertEqual(inner1.subviews.map { $0.frame.height }, [19, 16, 16])
    }

    func testFillNestedStackIsFlexible() {
        // Oracle probe probe_fill_nested: [label 34.5x19, vertical stack of
        // 22.5x16 / 41x16] in 300x60, spacing 8, alignment top -> the nested
        // stack (not the label) absorbs the slack: frame [43, 0, 257.5, 35].
        let s = makeFillStack(frame: CGRect(x: 10, y: 10, width: 300, height: 60),
                              spacing: 8, alignment: .top)
        let label = IntrinsicView(34.5, 19)
        let nested = UIStackView()
        nested.axis = .vertical
        nested.spacing = 3
        nested.alignment = .leading
        nested.addArrangedSubview(IntrinsicView(22.5, 16))
        nested.addArrangedSubview(IntrinsicView(41, 16))
        s.addArrangedSubview(label)
        s.addArrangedSubview(nested)
        s.layoutSubviews()
        XCTAssertEqual(label.frame, CGRect(x: 0, y: 0, width: 34.5, height: 19))
        XCTAssertEqual(nested.frame, CGRect(x: 43, y: 0, width: 257.5, height: 35))
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

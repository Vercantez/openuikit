// View-module tests: UIKit autoresizing-mask distribution.
import XCTest
@testable import OpenUIKit

// XCTest re-exports Foundation/CoreGraphics on Darwin; pin the portable types.

final class AutoresizingTests: XCTestCase {

    private func makeParent(_ w: CGFloat = 100, _ h: CGFloat = 100) -> UIView {
        UIView(frame: CGRect(x: 0, y: 0, width: w, height: h))
    }

    func testAllFixedMaskNoChange() {
        let parent = makeParent()
        let child = UIView(frame: CGRect(x: 10, y: 10, width: 40, height: 40))
        parent.addSubview(child)
        parent.frame = CGRect(x: 0, y: 0, width: 200, height: 150)
        XCTAssertEqual(child.frame, CGRect(x: 10, y: 10, width: 40, height: 40))
    }

    func testFlexibleWidthAbsorbsFullDelta() {
        let parent = makeParent()
        let child = UIView(frame: CGRect(x: 10, y: 0, width: 40, height: 20))
        child.autoresizingMask = [.flexibleWidth]
        parent.addSubview(child)
        parent.frame = CGRect(x: 0, y: 0, width: 160, height: 100)
        // Fixed margins stay; the width takes all 60pt of delta.
        XCTAssertEqual(child.frame, CGRect(x: 10, y: 0, width: 100, height: 20))
    }

    func testProportionalDistributionWidthAndMargins() {
        // left = 10, width = 40, right = 50; all flexible; delta = +60.
        // Shares: 10/100, 40/100, 50/100 → +6, +24, +30.
        let parent = makeParent()
        let child = UIView(frame: CGRect(x: 10, y: 0, width: 40, height: 10))
        child.autoresizingMask = [.flexibleLeftMargin, .flexibleWidth, .flexibleRightMargin]
        parent.addSubview(child)
        parent.frame = CGRect(x: 0, y: 0, width: 160, height: 100)
        XCTAssertEqual(child.frame.origin.x, 16, accuracy: 1e-9)
        XCTAssertEqual(child.frame.width, 64, accuracy: 1e-9)
        // Right margin: 160 - 16 - 64 = 80 = 50 + 30.
        XCTAssertEqual(160 - child.frame.maxX, 80, accuracy: 1e-9)
    }

    func testFlexibleMarginsOnlySplitProportionally() {
        // left = 20, right = 20 flexible, width fixed 60; delta = +40 → +20 each.
        let parent = makeParent()
        let child = UIView(frame: CGRect(x: 20, y: 0, width: 60, height: 10))
        child.autoresizingMask = [.flexibleLeftMargin, .flexibleRightMargin]
        parent.addSubview(child)
        parent.frame = CGRect(x: 0, y: 0, width: 140, height: 100)
        XCTAssertEqual(child.frame, CGRect(x: 40, y: 0, width: 60, height: 10))
    }

    func testAsymmetricMarginsSplitProportionally() {
        // left = 30 flexible, right = 10 flexible, width fixed 60; delta = +80.
        // Shares: 30/40 and 10/40 → left +60, right +20.
        let parent = makeParent()
        let child = UIView(frame: CGRect(x: 30, y: 0, width: 60, height: 10))
        child.autoresizingMask = [.flexibleLeftMargin, .flexibleRightMargin]
        parent.addSubview(child)
        parent.frame = CGRect(x: 0, y: 0, width: 180, height: 100)
        XCTAssertEqual(child.frame.origin.x, 90, accuracy: 1e-9)
        XCTAssertEqual(child.frame.width, 60, accuracy: 1e-9)
    }

    func testZeroSizeFlexibleComponentsSplitEqually() {
        // Every flexible component is zero → the delta splits equally.
        let parent = makeParent()
        let child = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
        child.autoresizingMask = [.flexibleLeftMargin, .flexibleWidth]
        parent.addSubview(child)
        parent.frame = CGRect(x: 0, y: 0, width: 130, height: 100)
        XCTAssertEqual(child.frame.origin.x, 15, accuracy: 1e-9)
        XCTAssertEqual(child.frame.width, 15, accuracy: 1e-9)
    }

    func testProportionalWhenOnlyOneComponentNonzero() {
        // frame (100,y,0,h) in a 100-wide parent: lead=100, size=0, trail=0.
        // Nonzero total → proportional: all delta goes to the lead margin.
        let parent = makeParent()
        let child = UIView(frame: CGRect(x: 100, y: 0, width: 0, height: 10))
        child.autoresizingMask = [.flexibleLeftMargin, .flexibleWidth, .flexibleRightMargin]
        parent.addSubview(child)
        parent.frame = CGRect(x: 0, y: 0, width: 150, height: 100)
        XCTAssertEqual(child.frame.origin.x, 150, accuracy: 1e-9)
        XCTAssertEqual(child.frame.width, 0, accuracy: 1e-9)
    }

    func testVerticalAxisIndependent() {
        // Height flexible, top margin flexible: top = 20, height = 30, bottom = 50 (fixed).
        // delta = +50, shares 20/50 & 30/50 → top +20, height +30.
        let parent = makeParent()
        let child = UIView(frame: CGRect(x: 0, y: 20, width: 10, height: 30))
        child.autoresizingMask = [.flexibleTopMargin, .flexibleHeight]
        parent.addSubview(child)
        parent.frame = CGRect(x: 0, y: 0, width: 100, height: 150)
        XCTAssertEqual(child.frame.origin.y, 40, accuracy: 1e-9)
        XCTAssertEqual(child.frame.height, 60, accuracy: 1e-9)
        // Horizontal untouched.
        XCTAssertEqual(child.frame.origin.x, 0)
        XCTAssertEqual(child.frame.width, 10)
    }

    func testShrinkingDistributesNegativeDelta() {
        // delta = -50 with left/width/right = 10/40/50 → -5, -20, -25.
        let parent = makeParent()
        let child = UIView(frame: CGRect(x: 10, y: 0, width: 40, height: 10))
        child.autoresizingMask = [.flexibleLeftMargin, .flexibleWidth, .flexibleRightMargin]
        parent.addSubview(child)
        parent.frame = CGRect(x: 0, y: 0, width: 50, height: 100)
        XCTAssertEqual(child.frame.origin.x, 5, accuracy: 1e-9)
        XCTAssertEqual(child.frame.width, 20, accuracy: 1e-9)
    }

    func testAutoresizesSubviewsOffDisablesDistribution() {
        let parent = makeParent()
        parent.autoresizesSubviews = false
        let child = UIView(frame: CGRect(x: 10, y: 10, width: 40, height: 40))
        child.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        parent.addSubview(child)
        parent.frame = CGRect(x: 0, y: 0, width: 200, height: 200)
        XCTAssertEqual(child.frame, CGRect(x: 10, y: 10, width: 40, height: 40))
    }

    func testCascadesToGrandchildren() {
        let parent = makeParent()
        let child = UIView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        child.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        let grand = UIView(frame: CGRect(x: 0, y: 0, width: 50, height: 50))
        grand.autoresizingMask = [.flexibleWidth]
        child.addSubview(grand)
        parent.addSubview(child)
        parent.frame = CGRect(x: 0, y: 0, width: 200, height: 100)
        XCTAssertEqual(child.frame.width, 200, accuracy: 1e-9)
        // Grandchild reacts to the child's resize: width 50 + delta 100
        // shared between fixed right margin (50)… width flexible only → +100.
        XCTAssertEqual(grand.frame.width, 150, accuracy: 1e-9)
    }

    func testSettingBoundsAlsoTriggersAutoresize() {
        let parent = makeParent()
        let child = UIView(frame: CGRect(x: 0, y: 0, width: 50, height: 50))
        child.autoresizingMask = [.flexibleWidth]
        parent.addSubview(child)
        parent.bounds = CGRect(x: 0, y: 0, width: 130, height: 100)
        XCTAssertEqual(child.frame.width, 80, accuracy: 1e-9)
    }

    func testOriginOnlyBoundsChangeDoesNotResize() {
        let parent = makeParent()
        let child = UIView(frame: CGRect(x: 0, y: 0, width: 50, height: 50))
        child.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        parent.addSubview(child)
        parent.bounds.origin = CGPoint(x: 10, y: 10)
        XCTAssertEqual(child.frame, CGRect(x: 0, y: 0, width: 50, height: 50))
    }
}

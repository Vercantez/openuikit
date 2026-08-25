// UIRefreshControl / UISearchBar / UIStepper tests.
// Owner: controls module (app-compat cluster "controls2").
//
// The refresh control has a golden (`fixtures/scenes/control_refresh.json`);
// the search bar and the stepper cannot have one, for the reasons their file
// headers give (a private material that does not composite offscreen, and a
// SwiftUI hosting view that renders nothing at all). These tests are the
// regression gate for the parts that WERE measurable: the geometry read off
// real UIKit's view tree, and the behaviour.

import XCTest
@testable import OpenUIKit

private typealias CGFloat = OpenUIKit.CGFloat
private typealias CGPoint = OpenUIKit.CGPoint
private typealias CGSize = OpenUIKit.CGSize
private typealias CGRect = OpenUIKit.CGRect

@MainActor
final class UIRefreshControlTests: XCTestCase {

    private func makeScrollView() -> (UIScrollView, UIRefreshControl) {
        let sv = UIScrollView(frame: CGRect(x: 0, y: 0, width: 320, height: 400))
        sv.contentSize = CGSize(width: 320, height: 2000)
        let rc = UIRefreshControl()
        sv.refreshControl = rc
        sv.layoutIfNeeded()
        return (sv, rc)
    }

    /// Measured: the control is the scroll view's FIRST subview, 60 pt tall,
    /// full width, hidden at rest, and its origin tracks contentOffset.
    func testMeasuredFrameTracksTheOffset() {
        let (sv, rc) = makeScrollView()
        XCTAssertTrue(sv.subviews.first === rc)
        XCTAssertTrue(rc.isHidden)
        XCTAssertEqual(rc.frame, CGRect(x: 0, y: 0, width: 320, height: 60))
        for offset in stride(from: 0.0, through: -200.0, by: -20.0) {
            sv.contentOffset.y = CGFloat(offset)
            sv.layoutIfNeeded()
            XCTAssertEqual(rc.frame,
                           CGRect(x: 0, y: CGFloat(offset), width: 320, height: 60),
                           "offset \(offset)")
        }
    }

    /// UIKit documents that a PROGRAMMATIC `beginRefreshing()` does not
    /// scroll the view, and the oracle agrees (the golden's control keeps
    /// frame (0, 0, W, 60)).
    func testProgrammaticBeginDoesNotMoveTheScrollView() {
        let (sv, rc) = makeScrollView()
        rc.beginRefreshing()
        sv.layoutIfNeeded()
        XCTAssertTrue(rc.isRefreshing)
        XCTAssertFalse(rc.isHidden)
        XCTAssertEqual(sv.contentOffset.y, 0)
        XCTAssertEqual(sv.contentInset.top, 0)
        XCTAssertEqual(rc.frame.minY, 0)
        rc.endRefreshing()
        XCTAssertFalse(rc.isRefreshing)
        XCTAssertTrue(rc.isHidden)
        XCTAssertEqual(sv.contentInset.top, 0)
    }

    /// The pull-to-refresh RULE (threshold = the control's height, released;
    /// then hold the inset open) is UIKit's documented behaviour, not a
    /// measurement — see UIRefreshControl.swift. This test pins the
    /// implementation of it, driving a REAL pan through the window.
    func testPullPastTheThresholdAndReleaseStartsARefresh() {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 320, height: 400))
        let sv = UIScrollView(frame: CGRect(x: 0, y: 0, width: 320, height: 400))
        sv.contentSize = CGSize(width: 320, height: 2000)
        let rc = UIRefreshControl()
        sv.refreshControl = rc
        window.addSubview(sv)
        window.layoutIfNeeded()
        var fired = 0
        rc.addTarget(for: .valueChanged) { _, _ in fired += 1 }

        // A short pull (30 pt of travel past the 10 pt slop) arms nothing.
        window.sendTouch(.began, at: CGPoint(x: 160, y: 100), timestamp: 0)
        window.sendTouch(.moved, at: CGPoint(x: 160, y: 140), timestamp: 0.05)
        XCTAssertLessThan(sv.contentOffset.y, 0)
        XCTAssertFalse(rc.isHidden, "the control shows as soon as the pull starts")
        window.sendTouch(.ended, at: CGPoint(x: 160, y: 140), timestamp: 0.1)
        XCTAssertFalse(rc.isRefreshing)
        XCTAssertEqual(fired, 0)

        // A pull that EXPOSES more than 60 pt, released, refreshes and holds
        // the inset open. Note the drag has to be much longer than 60 pt: the
        // measured rubber band (c = 0.55) turns 250 pt of travel into about
        // 100 pt of offset, which is exactly how far a real finger travels
        // to trip a real refresh control.
        sv.setContentOffset(.zero, animated: false)
        window.sendTouch(.began, at: CGPoint(x: 160, y: 60), timestamp: 1.0)
        window.sendTouch(.moved, at: CGPoint(x: 160, y: 320), timestamp: 1.05)
        XCTAssertLessThan(sv.contentOffset.y, -60)
        window.sendTouch(.ended, at: CGPoint(x: 160, y: 200), timestamp: 1.1)
        XCTAssertTrue(rc.isRefreshing)
        XCTAssertEqual(fired, 1)
        XCTAssertEqual(sv.contentInset.top, 60)

        rc.endRefreshing()
        XCTAssertEqual(sv.contentInset.top, 0)
        XCTAssertFalse(rc.isRefreshing)
    }

    func testReplacingTheControlRemovesTheOldOne() {
        let (sv, rc) = makeScrollView()
        let other = UIRefreshControl()
        sv.refreshControl = other
        XCTAssertNil(rc.superview)
        XCTAssertTrue(sv.subviews.first === other)
        sv.refreshControl = nil
        XCTAssertNil(other.superview)
    }
}

@MainActor
final class UISearchBarTests: XCTestCase {

    /// Measured: (width, 44) at every height.
    func testMeasuredSizeThatFits() {
        for h in [36.0, 44.0, 56.0, 80.0] as [CGFloat] {
            let sb = UISearchBar(frame: CGRect(x: 0, y: 0, width: 320, height: h))
            XCTAssertEqual(sb.sizeThatFits(CGSize(width: 320, height: 0)),
                           CGSize(width: 320, height: 44), "H=\(h)")
        }
        let sb = UISearchBar(frame: CGRect(x: 0, y: 0, width: 320, height: 44))
        XCTAssertEqual(sb.intrinsicContentSize.height, 44)
        XCTAssertEqual(sb.intrinsicContentSize.width, UIView.noIntrinsicMetric)
    }

    /// Measured field frames: (8, (H - 44) / 2, W - 16, 36), over the six
    /// heights and three widths the probe covered.
    func testMeasuredFieldFrame() {
        let heights: [(CGFloat, CGFloat)] = [(36, -4), (44, 0), (50, 3),
                                             (56, 6), (60, 8), (80, 18)]
        for (h, y) in heights {
            let sb = UISearchBar(frame: CGRect(x: 0, y: 0, width: 320, height: h))
            sb.placeholder = "Search"
            sb.layoutIfNeeded()
            XCTAssertEqual(sb.searchTextField.frame,
                           CGRect(x: 8, y: y, width: 304, height: 36), "H=\(h)")
        }
        for w in [200.0, 320.0, 375.0] as [CGFloat] {
            let sb = UISearchBar(frame: CGRect(x: 0, y: 0, width: w, height: 44))
            sb.layoutIfNeeded()
            XCTAssertEqual(sb.searchTextField.frame,
                           CGRect(x: 8, y: 0, width: w - 16, height: 36), "W=\(w)")
        }
    }

    /// Measured: the field's font is system MEDIUM 17 and the text starts
    /// 39.5 pt in, with 34.5 pt reserved on the right once there is text.
    func testMeasuredTextMetrics() {
        let sb = UISearchBar(frame: CGRect(x: 0, y: 0, width: 320, height: 44))
        sb.placeholder = "Search"
        sb.layoutIfNeeded()
        XCTAssertEqual(sb.searchTextField.font.pointSize, 17)
        XCTAssertEqual(sb.searchTextField.font.weight, UIFont.Weight.medium)
        let empty = sb.searchTextField.textRect(
            forBounds: CGRect(x: 0, y: 0, width: 304, height: 36))
        XCTAssertEqual(empty, CGRect(x: 39.5, y: 0, width: 264.5, height: 36))
        sb.text = "Hello"
        let filled = sb.searchTextField.textRect(
            forBounds: CGRect(x: 0, y: 0, width: 304, height: 36))
        XCTAssertEqual(filled, CGRect(x: 39.5, y: 0, width: 230, height: 36))
    }

    func testCancelButtonShrinksTheField() {
        let sb = UISearchBar(frame: CGRect(x: 0, y: 0, width: 320, height: 44))
        sb.layoutIfNeeded()
        let full = sb.searchTextField.frame.width
        sb.setShowsCancelButton(true, animated: false)
        sb.layoutIfNeeded()
        XCTAssertLessThan(sb.searchTextField.frame.width, full)
        XCTAssertEqual(sb.searchTextField.frame.minX, 8)
        sb.setShowsCancelButton(false, animated: false)
        sb.layoutIfNeeded()
        XCTAssertEqual(sb.searchTextField.frame.width, full)
    }

    func testDelegateHearsTextChanges() {
        @MainActor
        final class D: UISearchBarDelegate {
            var seen: [String] = []
            func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
                seen.append(searchText)
            }
        }
        let d = D()
        let sb = UISearchBar(frame: CGRect(x: 0, y: 0, width: 320, height: 44))
        sb.delegate = d
        sb._textDidChange()
        sb.text = "abc"
        sb._textDidChange()
        XCTAssertEqual(d.seen, ["", "abc"])
    }

    /// `.minimal` suppresses the pill — the only part of `searchBarStyle`
    /// that is implemented (file header).
    func testMinimalStyleDropsTheFieldBackground() {
        let sb = UISearchBar(frame: CGRect(x: 0, y: 0, width: 320, height: 44))
        XCTAssertTrue(sb.searchTextField.drawsFieldBackground)
        sb.searchBarStyle = .minimal
        XCTAssertFalse(sb.searchTextField.drawsFieldBackground)
    }
}

@MainActor
final class UIStepperTests: XCTestCase {

    /// Measured intrinsic size and UIKit's documented defaults, both read off
    /// a live control.
    func testMeasuredIntrinsicSizeAndDefaults() {
        let s = UIStepper()
        XCTAssertEqual(s.intrinsicContentSize, CGSize(width: 94, height: 32))
        XCTAssertEqual(s.sizeThatFits(CGSize(width: 500, height: 500)),
                       CGSize(width: 94, height: 32))
        XCTAssertEqual(s.frame.size, CGSize(width: 94, height: 32))
        XCTAssertEqual(s.value, 0)
        XCTAssertEqual(s.minimumValue, 0)
        XCTAssertEqual(s.maximumValue, 100)
        XCTAssertEqual(s.stepValue, 1)
        XCTAssertTrue(s.isContinuous)
        XCTAssertTrue(s.autorepeat)
        XCTAssertFalse(s.wraps)
    }

    func testSteppingClampsAtBothEnds() {
        let s = UIStepper()
        s.minimumValue = 2
        s.maximumValue = 5
        s.stepValue = 2
        s.value = 2
        XCTAssertTrue(s.step(1))
        XCTAssertEqual(s.value, 4)
        XCTAssertTrue(s.step(1))
        XCTAssertEqual(s.value, 5, "clamped to the maximum")
        XCTAssertFalse(s.step(1), "already at the maximum")
        s.value = 2
        XCTAssertFalse(s.step(-1), "clamped at the minimum, no change")
        XCTAssertEqual(s.value, 2)
    }

    func testWrapsGoesRoundBothWays() {
        let s = UIStepper()
        s.minimumValue = 0
        s.maximumValue = 3
        s.wraps = true
        s.value = 3
        s.step(1)
        XCTAssertEqual(s.value, 0)
        s.step(-1)
        XCTAssertEqual(s.value, 3)
    }

    func testSettingValueOutOfRangeClamps() {
        let s = UIStepper()
        s.maximumValue = 10
        s.value = 99
        XCTAssertEqual(s.value, 10)
        s.value = -5
        XCTAssertEqual(s.value, 0)
    }

    /// The left half decrements, the right half increments, and
    /// `.valueChanged` respects `isContinuous`.
    func testTouchHalvesAndValueChanged() {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 200, height: 100))
        let s = UIStepper()
        s.frame = CGRect(x: 10, y: 10, width: 94, height: 32)
        window.addSubview(s)
        window.layoutIfNeeded()
        var fired = 0
        s.addTarget(for: .valueChanged) { _, _ in fired += 1 }
        s.value = 5

        // Left half: x 10..57 in window coordinates.
        window.sendTouch(.began, at: CGPoint(x: 30, y: 26), timestamp: 0)
        window.sendTouch(.ended, at: CGPoint(x: 30, y: 26), timestamp: 0.05)
        XCTAssertEqual(s.value, 4)
        XCTAssertEqual(fired, 1)

        // Right half: x 57..104.
        window.sendTouch(.began, at: CGPoint(x: 84, y: 26), timestamp: 1.0)
        window.sendTouch(.ended, at: CGPoint(x: 84, y: 26), timestamp: 1.05)
        XCTAssertEqual(s.value, 5)
        XCTAssertEqual(fired, 2)

        // Non-continuous: the event waits for the lift.
        s.isContinuous = false
        window.sendTouch(.began, at: CGPoint(x: 84, y: 26), timestamp: 2.0)
        XCTAssertEqual(s.value, 6)
        XCTAssertEqual(fired, 2, "no event yet")
        window.sendTouch(.ended, at: CGPoint(x: 84, y: 26), timestamp: 2.05)
        XCTAssertEqual(fired, 3)
    }
}

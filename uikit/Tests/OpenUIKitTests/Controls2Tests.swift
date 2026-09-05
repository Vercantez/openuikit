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

#if !os(Linux)
@MainActor
#endif
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

#if !os(Linux)
@MainActor
#endif
final class UIRefreshControlIOSCutTests: XCTestCase {
    private var savedCut: FontEngine.SystemFontCut!

    override func setUp() {
        super.setUp()
        savedCut = OpenUIKitRuntime.systemFontCut
        OpenUIKitRuntime.systemFontCut = .iOS
    }

    override func tearDown() {
        OpenUIKitRuntime.systemFontCut = savedCut
        super.tearDown()
    }

    /// MEASURED Feed t200/t700/t2800, iPhone SE 2x / iOS 26.1: window
    /// abs.y of the control is 64 at every contentOffset, i.e.
    /// frame.y = contentOffset.y + 64, once the scroll view is under a
    /// navigation overlay (adjustedContentInset.top >= 64).
    func testIOSFrameSits64BelowTheOffsetWhenUnderANavOverlay() {
        let sv = UIScrollView(frame: CGRect(x: 0, y: 0, width: 375, height: 667))
        sv.contentSize = CGSize(width: 375, height: 2000)
        sv._setSafeAreaInsets(UIEdgeInsets(top: 116, left: 0, bottom: 0, right: 0))
        let rc = UIRefreshControl()
        sv.refreshControl = rc
        sv.contentOffset.y = -116
        sv.layoutIfNeeded()
        XCTAssertEqual(rc.frame, CGRect(x: 0, y: -52, width: 375, height: 60))
        sv.contentOffset.y = -236
        sv.layoutIfNeeded()
        XCTAssertEqual(rc.frame, CGRect(x: 0, y: -172, width: 375, height: 60))
        sv.contentOffset.y = 352
        sv.layoutIfNeeded()
        XCTAssertEqual(rc.frame, CGRect(x: 0, y: 416, width: 375, height: 60))
    }

    /// MEASURED Feed t700, iPhone SE 2x / iOS 26.1: beginRefreshing while
    /// already overscrolled stretches the large-title bar 106 → 166
    /// (adj 116 → 176) and rebases offset −176 → −236. Stretch first,
    /// then subtract 60, or the safe-area rebase eats the extra 60.
    func testIOSBeginRefreshingStretchesLargeTitleAndRebasesOffset() {
        let vc = UIViewController()
        vc.title = "Feed"
        vc.navigationItem.largeTitleDisplayMode = .always
        let scroll = UIScrollView(frame: CGRect(x: 0, y: 0, width: 375, height: 667))
        scroll.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        scroll.contentSize = CGSize(width: 375, height: 2000)
        vc.view.addSubview(scroll)
        vc.setContentScrollView(scroll)
        let rc = UIRefreshControl()
        scroll.refreshControl = rc
        let nav = UINavigationController(rootViewController: vc)
        nav.navigationBar.prefersLargeTitles = true
        nav.view.frame = CGRect(x: 0, y: 0, width: 375, height: 667)
        nav.view.layoutIfNeeded()
        XCTAssertEqual(scroll.adjustedContentInset.top, 116, accuracy: 0.5)
        scroll.contentOffset.y = -scroll.adjustedContentInset.top - 60
        rc.beginRefreshing()
        XCTAssertEqual(scroll.contentOffset.y, -236, accuracy: 0.5)
        XCTAssertEqual(scroll.adjustedContentInset.top, 176, accuracy: 0.5)
        XCTAssertEqual(nav.navigationBar.frame.height, 166, accuracy: 0.5)
        XCTAssertEqual(rc.frame.origin.y, -172, accuracy: 0.5)
        XCTAssertEqual(rc.frame.height, 60)
    }

    /// Suite `control_refresh` (iOS cut): a rest offset of 0 with adj 0
    /// is not overscroll. beginRefreshing must leave the offset (and the
    /// control's frame.y) at 0 — a `y < adj + 0.5` slack had subtracted 60.
    func testIOSBeginRefreshingAtRestDoesNotMoveOffset() {
        let sv = UIScrollView(frame: CGRect(x: 0, y: 0, width: 320, height: 140))
        sv.contentSize = CGSize(width: 320, height: 600)
        let rc = UIRefreshControl()
        sv.refreshControl = rc
        sv.layoutIfNeeded()
        XCTAssertEqual(sv.contentOffset.y, 0)
        rc.beginRefreshing()
        sv.layoutIfNeeded()
        XCTAssertEqual(sv.contentOffset.y, 0)
        XCTAssertEqual(rc.frame.origin.y, 0)
    }

    /// A scroll view with no nav overlay keeps the Catalyst origin even
    /// on the iOS cut (control_refresh: frame (0, offset, W, 60)).
    func testIOSFrameWithoutNavOverlayTracksTheOffset() {
        let sv = UIScrollView(frame: CGRect(x: 0, y: 0, width: 320, height: 140))
        sv.contentSize = CGSize(width: 320, height: 600)
        let rc = UIRefreshControl()
        sv.refreshControl = rc
        sv.contentOffset.y = -40
        sv.layoutIfNeeded()
        XCTAssertEqual(rc.frame, CGRect(x: 0, y: -40, width: 320, height: 60))
    }

    /// MEASURED spinnerprobe rc_n0..24, iPhone SE 2x / iOS 26.1: replicator
    /// opacity is easeInOut (0.42, 0, 0.58, 1) over 1 s. Pager t4650 is
    /// frame 9 = 0.15 s → 0.04521; Feed t700 is frame 18 = 0.30 s → 0.18740.
    func testIOSAppearOpacityMatchesMeasuredEaseInOut() {
        XCTAssertEqual(UIRefreshControl.easeInOut(0), 0, accuracy: 1e-6)
        XCTAssertEqual(UIRefreshControl.easeInOut(1), 1, accuracy: 1e-6)
        XCTAssertEqual(UIRefreshControl.easeInOut(0.15), 0.04521, accuracy: 0.00001)
        XCTAssertEqual(UIRefreshControl.easeInOut(0.30), 0.18740, accuracy: 0.00001)
        let savedTime = OpenUIKitRuntime.animationTime
        defer { OpenUIKitRuntime.animationTime = savedTime }
        OpenUIKitRuntime.animationTime = 4.50
        let rc = UIRefreshControl()
        rc.beginRefreshing()
        OpenUIKitRuntime.animationTime = 4.65
        XCTAssertEqual(rc.appearElapsed, 0.15, accuracy: 1e-9)
        OpenUIKitRuntime.animationTime = 0.40
        let feed = UIRefreshControl()
        feed.beginRefreshing()
        OpenUIKitRuntime.animationTime = 0.70
        XCTAssertEqual(feed.appearElapsed, 0.30, accuracy: 1e-9)
    }
}

#if !os(Linux)
@MainActor
#endif
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
        #if !os(Linux)
        @MainActor
        #endif
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

/// The windowed iOS 26.1 oracle's numbers (fixtures `searchbar_placeholder`
/// and `searchbar_text_clear` on the iPhone 16 at 3x, plus the /tmp geometry,
/// fill and dark probes — see the `UISearchBar.swift` header). The class
/// above pins the Catalyst cut; this one pins the iOS cut.
#if !os(Linux)
@MainActor
#endif
final class UISearchBarIOSCutTests: XCTestCase {
    private var savedCut: FontEngine.SystemFontCut!
    private var savedBounds: CGRect!
    private var savedScale: CGFloat!

    override func setUp() {
        super.setUp()
        savedCut = OpenUIKitRuntime.systemFontCut
        savedBounds = UIScreen.main.bounds
        savedScale = UIScreen.main.scale
        OpenUIKitRuntime.systemFontCut = .iOS
        UIScreen.main._hostConfigure(bounds: CGRect(x: 0, y: 0, width: 393, height: 852),
                                     scale: 3)
    }

    override func tearDown() {
        OpenUIKitRuntime.systemFontCut = savedCut
        UIScreen.main._hostConfigure(bounds: savedBounds, scale: savedScale)
        super.tearDown()
    }

    /// MEASURED at eight bar heights and four widths: the field is
    /// (8, (H - 44) / 2, W - 16, 44) — 44 tall, not the Catalyst 36.
    func testFieldIs44TallAtEveryBarHeight() {
        let heights: [(CGFloat, CGFloat)] = [(30, -7), (36, -4), (40, -2), (44, 0),
                                             (50, 3), (56, 6), (60, 8), (80, 18)]
        for (h, y) in heights {
            let sb = UISearchBar(frame: CGRect(x: 0, y: 0, width: 393, height: h))
            sb.placeholder = "Search"
            sb.layoutIfNeeded()
            XCTAssertEqual(sb.searchTextField.frame,
                           CGRect(x: 8, y: y, width: 377, height: 44), "H=\(h)")
        }
        for w in [200.0, 320.0, 375.0, 393.0] as [CGFloat] {
            let sb = UISearchBar(frame: CGRect(x: 0, y: 0, width: w, height: 44))
            sb.layoutIfNeeded()
            XCTAssertEqual(sb.searchTextField.frame.width, w - 16, "W=\(w)")
        }
    }

    /// MEASURED: text starts 39.667 pt in at 3x (39.5 at 2x — the Catalyst
    /// number on its own grid), and the text box stops 44 pt short of the
    /// trailing edge once the clear button is there (golden canvas ends at
    /// 333 in a 377 pt field).
    func testTextInsetsFollowTheDevicePixel() {
        let sb = UISearchBar(frame: CGRect(x: 0, y: 0, width: 393, height: 44))
        sb.placeholder = "Search"
        sb.layoutIfNeeded()
        let bounds = CGRect(x: 0, y: 0, width: 377, height: 44)
        XCTAssertEqual(sb.searchTextField.textRect(forBounds: bounds).minX,
                       119.0 / 3, accuracy: 1e-9)
        sb.text = "Espresso"
        XCTAssertEqual(sb.searchTextField.textRect(forBounds: bounds).maxX, 333,
                       accuracy: 1e-9)
        UIScreen.main._hostConfigure(bounds: CGRect(x: 0, y: 0, width: 375, height: 667),
                                     scale: 2)
        XCTAssertEqual(UISearchTextField.textLeftInset, 39.5, accuracy: 1e-9)
    }

    /// MEASURED: (W - 34.333, 11.667, 20, 20) in fields 359 and 377 wide.
    func testClearButtonBox() {
        let sb = UISearchBar(frame: CGRect(x: 0, y: 0, width: 393, height: 44))
        sb.text = "Espresso"
        for width in [359.0, 377.0] as [CGFloat] {
            let r = sb.searchTextField.clearButtonRect(
                forBounds: CGRect(x: 0, y: 0, width: width, height: 44))
            XCTAssertEqual(r.minX, width - 103.0 / 3, accuracy: 1e-9, "W=\(width)")
            XCTAssertEqual(r.minY, 35.0 / 3, accuracy: 1e-9, "W=\(width)")
            XCTAssertEqual(r.size, CGSize(width: 20, height: 20), "W=\(width)")
        }
    }

    /// MEASURED ink: the magnifier, the placeholder and the clear glyph are
    /// all `secondaryLabel` — darkest (137, 137, 141) on the light pill and
    /// brightest (149, 149, 155) on the dark one.
    func testGlyphsUseSecondaryLabel() {
        let sb = UISearchBar(frame: CGRect(x: 0, y: 0, width: 393, height: 44))
        sb.placeholder = "Search"
        sb.layoutIfNeeded()
        let light = UITraitCollection(userInterfaceStyle: .light)
        let expected = UIColor.secondaryLabel.resolvedCGColor(with: light)
        let placeholder = sb.searchTextField.placeholderLabel
            .textColor.resolvedCGColor(with: light)
        XCTAssertEqual(placeholder.red, expected.red, accuracy: 1e-9)
        XCTAssertEqual(placeholder.alpha, expected.alpha, accuracy: 1e-9)
        XCTAssertEqual(_UISearchFieldMetrics.glyphColor.resolvedCGColor(with: light).alpha,
                       expected.alpha, accuracy: 1e-9)
    }

    /// MEASURED flat equivalent of the pill's glass material: (253, 253, 253)
    /// light, (19, 19, 19) dark, over eight backdrops.
    func testPillFillAndCapsule() {
        let sb = UISearchBar(frame: CGRect(x: 0, y: 0, width: 393, height: 44))
        sb.layoutIfNeeded()
        XCTAssertEqual(sb.searchTextField.layer.cornerRadius, 22, accuracy: 1e-9)
        let light = _UISearchFieldMetrics.pillFill
            .resolvedCGColor(with: UITraitCollection(userInterfaceStyle: .light))
        XCTAssertEqual(light.red, 253.0 / 255, accuracy: 1e-9)
        let dark = _UISearchFieldMetrics.pillFill
            .resolvedCGColor(with: UITraitCollection(userInterfaceStyle: .dark))
        XCTAssertEqual(dark.red, 19.0 / 255, accuracy: 1e-9)
        XCTAssertEqual(sb.searchTextField.layer.shadowOpacity, 0.07, accuracy: 1e-6)
        XCTAssertEqual(sb.searchTextField.layer.shadowRadius, 16, accuracy: 1e-9)
        XCTAssertEqual(sb.searchTextField.layer.shadowOffset.height, 7.5, accuracy: 1e-9)
    }

    /// MEASURED Tabs t4000.rtl, iPhone SE 2x / iOS 26.1: dismiss is on the
    /// trailing (left) edge — field abs [71, 18, 288, 44] = 16 + 44 + 11.
    func testNavInlineRTLPutsDismissOnTheTrailingEdge() {
        let sb = UISearchBar(frame: CGRect(x: 0, y: 0, width: 375, height: 80))
        sb.semanticContentAttribute = .forceRightToLeft
        sb._navInlineActive = true
        sb.layoutIfNeeded()
        XCTAssertEqual(sb.searchTextField.frame,
                       CGRect(x: 71, y: UISearchBar.navInlineFieldY, width: 288,
                              height: UISearchBar.fieldHeight))
        let dismiss = sb.subviews.compactMap { $0 as? UIButton }.first
        XCTAssertEqual(dismiss?.frame,
                       CGRect(x: 16, y: UISearchBar.navInlineFieldY, width: 44, height: 44))
    }
}

#if !os(Linux)
@MainActor
#endif
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

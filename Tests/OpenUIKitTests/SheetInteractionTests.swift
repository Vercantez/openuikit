// M11 interactive pageSheet tests. Every constant asserted here is MEASURED
// from real iOS 26.1 UIKit by Tools/oracle2/sheetprobe (scripts/
// sheet_probe_sim.sh); docs/APP_FEEL.md "Measured sheet interaction" records
// the traces and the fits. These tests pin the implementation to those
// numbers — they are a regression gate on the measurement, not a restatement
// of the code.
import XCTest
import Foundation
@testable import OpenUIKit

private typealias CGFloat = OpenUIKit.CGFloat
private typealias CGPoint = OpenUIKit.CGPoint
private typealias CGSize = OpenUIKit.CGSize
private typealias CGRect = OpenUIKit.CGRect

/// iPhone 16 portrait — the geometry every probe measurement was taken at.
private let windowSize = CGSize(width: 393, height: 852)

final class SheetInteractionTests: XCTestCase {
    override func setUp() {
        super.setUp()
        OpenUIKitRuntime.animationTime = 0
    }
    override func tearDown() {
        OpenUIKitRuntime.animationTime = 0
        super.tearDown()
    }

    // MARK: Harness

    /// A window with a base controller presenting a sheet. `scrollContent`
    /// puts a tall scroll view inside the sheet (for the hand-off tests).
    private func present(scrollContent: Bool = false)
        -> (window: UIWindow, base: UIViewController, sheetVC: UIViewController,
            sheet: _UIPageSheetView, dim: UIView, scroll: UIScrollView?) {
        let window = UIWindow(frame: CGRect(origin: .zero, size: windowSize))
        let base = UIViewController()
        base.view.frame = CGRect(origin: .zero, size: windowSize)
        window.addSubview(base.view)

        let vc = UIViewController()
        vc.view.backgroundColor = .systemBackground
        var scroll: UIScrollView?
        if scrollContent {
            let sv = UIScrollView(frame: CGRect(x: 0, y: 0, width: windowSize.width,
                                                height: windowSize.height))
            sv.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            sv.contentSize = CGSize(width: windowSize.width, height: 4000)
            let filler = UIView(frame: CGRect(x: 0, y: 0, width: windowSize.width,
                                              height: 4000))
            sv.addSubview(filler)
            vc.view.addSubview(sv)
            scroll = sv
        }
        base.present(vc, animated: false)
        window.layoutIfNeeded()
        let sheet = vc._presentationSheet!
        return (window, base, vc, sheet, vc._presentationDim!, scroll)
    }

    /// Drag `travel` points down from `startY`, one 16 ms step per 4 pt, then
    /// optionally hold still (killing the release velocity) and lift.
    @discardableResult
    private func drag(_ window: UIWindow, from startY: CGFloat, travel: CGFloat,
                      step: CGFloat = 4, interval: Double = 0.016,
                      hold: Double = 0.4, lift: Bool = true,
                      x: CGFloat = 196) -> Double {
        var t = 0.0
        window.sendTouch(.began, at: CGPoint(x: x, y: startY), timestamp: t)
        var y = startY
        let steps = Int((travel / step).rounded())
        for _ in 0..<steps {
            t += interval
            y += step
            window.sendTouch(.moved, at: CGPoint(x: x, y: y), timestamp: t)
        }
        var held = 0.0
        while held < hold {
            t += interval
            held += interval
            window.sendTouch(.moved, at: CGPoint(x: x, y: y), timestamp: t)
        }
        if lift {
            t += interval
            window.sendTouch(.ended, at: CGPoint(x: x, y: y), timestamp: t)
        }
        return t
    }

    /// Run the host clock forward, ticking the window each frame.
    private func run(_ window: UIWindow, from t0: Double, to t1: Double,
                     dt: Double = 1.0 / 60) {
        var t = t0
        while t < t1 {
            t += dt
            OpenUIKitRuntime.animationTime = t
            window.tick(timestamp: t)
        }
    }

    // MARK: Static geometry (measured)

    func testSheetRestGeometryMatchesTheProbe() {
        let s = present()
        // MEASURED: real iOS reports the sheet frame as (0, 59, 393, 793).
        XCTAssertEqual(s.sheet.frame.minY, 59, accuracy: 0.001)
        XCTAssertEqual(s.sheet.frame.height, 793, accuracy: 0.001)
        XCTAssertEqual(s.sheet.frame.width, 393, accuracy: 0.001)
        // MEASURED: the dim is black at exactly 0.2.
        XCTAssertEqual(s.dim.alpha, 0.2, accuracy: 0.0001)
    }

    func testGrabberIsHiddenByDefaultAndMeasuredWhenShown() {
        let s = present()
        XCTAssertTrue(s.sheet.subviews.compactMap { $0 as? _UISheetGrabber }.isEmpty,
                      "UIKit's prefersGrabberVisible default is false")

        s.sheetVC.sheetPresentationController?.prefersGrabberVisible = true
        guard let g = s.sheet.subviews.compactMap({ $0 as? _UISheetGrabber }).first else {
            return XCTFail("grabber not installed")
        }
        // MEASURED: _UIGrabber [178.5, 64.0, 36.0, 5.0], cornerRadius 2.5,
        // where 64.0 is 5 pt below the sheet's top edge at y = 59.
        XCTAssertEqual(g.frame.minX, 178.5, accuracy: 0.001)
        XCTAssertEqual(g.frame.minY, 5, accuracy: 0.001)   // sheet-relative
        XCTAssertEqual(g.frame.width, 36, accuracy: 0.001)
        XCTAssertEqual(g.frame.height, 5, accuracy: 0.001)
        XCTAssertEqual(g.layer.cornerRadius, 2.5, accuracy: 0.001)

        s.sheetVC.sheetPresentationController?.prefersGrabberVisible = false
        XCTAssertTrue(s.sheet.subviews.compactMap { $0 as? _UISheetGrabber }.isEmpty)
    }

    // MARK: Tracking + dim law (measured)

    func testDragTracksOneToOneAfterExactlyTenPointsOfSlop() {
        // MEASURED at five distances: sheet offset == finger travel − 10.
        for travel in [CGFloat(180), 240, 320, 360, 380] {
            let s = present()
            drag(s.window, from: 200, travel: travel, hold: 0, lift: false)
            XCTAssertEqual(s.sheet.dragOffset, travel - UISheetPhysics.panSlop,
                           accuracy: 0.001, "travel \(travel)")
            XCTAssertEqual(s.sheet.frame.minY, 59 + travel - 10, accuracy: 0.001)
        }
    }

    func testDimmingIsExactlyLinearInDragProgress() {
        let s = present()
        let h = s.sheet.frame.height
        for travel in stride(from: CGFloat(40), through: 400, by: 40) {
            let f = present()
            drag(f.window, from: 200, travel: travel, hold: 0, lift: false)
            // MEASURED: alpha = 0.2 · (1 − offset / sheetHeight), residual
            // never worse than 0.0025 over four full real-UIKit drags.
            let expected = 0.2 * (1 - (travel - 10) / h)
            XCTAssertEqual(f.dim.alpha, expected, accuracy: 0.0001,
                           "travel \(travel)")
        }
    }

    func testSheetDoesNotMoveUpwardPastItsDetent() {
        // MEASURED: dragging UP on a large-detent sheet moves nothing at all
        // — real iOS applies no rubber band above the top detent, and the
        // dim stays at full strength.
        let s = present()
        var t = 0.0
        s.window.sendTouch(.began, at: CGPoint(x: 196, y: 400), timestamp: t)
        for i in 1...40 {
            t += 0.016
            s.window.sendTouch(.moved, at: CGPoint(x: 196, y: 400 - CGFloat(i) * 4),
                               timestamp: t)
        }
        XCTAssertEqual(s.sheet.dragOffset, 0, accuracy: 0.001)
        XCTAssertEqual(s.sheet.frame.minY, 59, accuracy: 0.001)
        XCTAssertEqual(s.dim.alpha, 0.2, accuracy: 0.0001)
    }

    // MARK: Release rule (measured)

    func testReleaseAtRestUnderHalfTheHeightSpringsBack() {
        // MEASURED: 370 pt of a 793 pt sheet (46.7 %) springs back.
        let s = present()
        let t = drag(s.window, from: 150, travel: 380)
        XCTAssertNotNil(s.sheet.settle)
        XCTAssertEqual(s.sheet.settle?.target, 0)
        run(s.window, from: t, to: t + 1.2)
        XCTAssertEqual(s.sheet.dragOffset, 0, accuracy: 0.001)
        XCTAssertEqual(s.sheet.frame.minY, 59, accuracy: 0.001)
        XCTAssertEqual(s.dim.alpha, 0.2, accuracy: 0.0001)
        XCTAssertTrue(s.base.presentedViewController === s.sheetVC,
                      "spring-back must NOT dismiss")
    }

    func testReleaseAtRestPastHalfTheHeightDismisses() {
        // MEASURED: 398/402 pt of a 793 pt sheet (> 50 %) dismisses.
        let s = present()
        let t = drag(s.window, from: 100, travel: 412)
        XCTAssertEqual(s.sheet.settle?.target, s.sheet.frame.height)
        run(s.window, from: t, to: t + 1.5)
        XCTAssertNil(s.base.presentedViewController)
        XCTAssertNil(s.sheetVC.presentingViewController)
        XCTAssertNil(s.sheetVC.viewIfLoaded?.superview)
    }

    func testFlickDismissesAtExactlyOneThousandPointsPerSecond() {
        // MEASURED: at 64 pt of travel, 975 pt/s springs back and 1000 pt/s
        // dismisses. 64 pt is 8 % of the sheet — nowhere near the distance
        // rule, so this isolates the velocity rule.
        for (v, shouldDismiss) in [(CGFloat(900), false), (CGFloat(1200), true)] {
            let s = present()
            let step = v * 0.008
            let t = drag(s.window, from: 150, travel: 64, step: step,
                         interval: 0.008, hold: 0)
            run(s.window, from: t, to: t + 1.5)
            if shouldDismiss {
                XCTAssertNil(s.base.presentedViewController, "v=\(v) must dismiss")
            } else {
                XCTAssertTrue(s.base.presentedViewController === s.sheetVC,
                              "v=\(v) must spring back")
            }
        }
    }

    func testIsModalInPresentationSuppressesTheDismissal() {
        let s = present()
        s.sheetVC.isModalInPresentation = true
        let t = drag(s.window, from: 100, travel: 500)
        XCTAssertEqual(s.sheet.settle?.target, 0, "must spring back")
        run(s.window, from: t, to: t + 1.5)
        XCTAssertTrue(s.base.presentedViewController === s.sheetVC)
        XCTAssertEqual(s.sheet.dragOffset, 0, accuracy: 0.001)
    }

    // MARK: Settle spring (measured)

    func testSettleFollowsTheMeasuredCriticallyDampedSpring() {
        // MEASURED omega = sqrt(1000/3) = 18.2574 (free fits of three real
        // releases: 18.251 / 18.256 / 18.258, rms 0.02-0.05 pt).
        XCTAssertEqual(UISheetPhysics.settleOmega,
                       (1000.0 / 3.0).squareRoot(), accuracy: 1e-9)

        // Released from rest at x0, the closed form is x0·(1+wt)·e^(−wt).
        let x0: CGFloat = 170, w = UISheetPhysics.settleOmega
        for t in [0.0, 0.02, 0.05, 0.1, 0.2, 0.4] {
            let expected = Double(x0) * (1 + w * t) * _scrollExp(-w * t)
            XCTAssertEqual(Double(UISheetPhysics.displacement(x0: x0, v0: 0, at: t)),
                           expected, accuracy: 1e-6, "t=\(t)")
        }
        // Against the oracle trace itself (sheet_drag_track_down: released at
        // rest from 170 pt, offsets recovered from the dim alpha). Trace
        // times are shifted by the 6.2 ms the fit attributes to touch
        // delivery — UIKit starts the spring about one event late, the same
        // lag compare_scroll.py aligns out of the deceleration traces.
        let lag = 0.0062
        for (traceT, measured) in [(0.0553, 132.35), (0.0886, 95.27),
                                   (0.1553, 41.97), (0.2553, 10.09),
                                   (0.3553, 2.16)] {
            XCTAssertEqual(
                Double(UISheetPhysics.displacement(x0: 170, v0: 0, at: traceT - lag)),
                measured, accuracy: 1.0, "trace t=\(traceT)")
        }
    }

    func testSettleRunsOnTheHostClockNotTheWallClock() {
        let s = present()
        let t = drag(s.window, from: 150, travel: 200)
        let mid = s.sheet.dragOffset
        XCTAssertEqual(mid, 190, accuracy: 0.001)
        // No ticks -> no movement at all.
        XCTAssertEqual(s.sheet.dragOffset, 190, accuracy: 0.001)
        XCTAssertTrue(UIViewController._hasActiveSheetInteraction)
        run(s.window, from: t, to: t + 0.1)
        XCTAssertLessThan(s.sheet.dragOffset, 120, "must be springing back")
        run(s.window, from: t + 0.1, to: t + 1.0)
        XCTAssertEqual(s.sheet.dragOffset, 0, accuracy: 0.001)
        XCTAssertFalse(UIViewController._hasActiveSheetInteraction)
    }

    func testDragTakesOverFromAnAnimatedPresent() {
        // Regression: a FINISHED UIView.animate still pins the presentation
        // to its recorded end value, so a sheet presented with animated:true
        // used to move its model under the finger while the screen stayed
        // put. The drag must clear the present animation off both the sheet
        // and the dim.
        let window = UIWindow(frame: CGRect(origin: .zero, size: windowSize))
        let base = UIViewController()
        base.view.frame = CGRect(origin: .zero, size: windowSize)
        window.addSubview(base.view)
        let vc = UIViewController()
        vc.view.backgroundColor = .systemBackground
        base.present(vc, animated: true)
        window.layoutIfNeeded()
        let sheet = vc._presentationSheet!
        let dim = vc._presentationDim!
        // Let the 0.4 s present spring finish on the host clock.
        run(window, from: 0, to: 0.6)
        XCTAssertTrue(sheet.animations.isEmpty == false || dim.animations.isEmpty == false,
                      "precondition: the present animation is still recorded")

        drag(window, from: 300, travel: 200, hold: 0, lift: false)
        XCTAssertEqual(sheet.dragOffset, 190, accuracy: 0.001)
        XCTAssertTrue(sheet.animations.isEmpty,
                      "the drag must own the frame, not a stale animation")
        XCTAssertTrue(dim.animations.isEmpty)
        XCTAssertEqual(sheet.frame.minY, 59 + 190, accuracy: 0.001)
    }

    // MARK: Sheet / scroll hand-off (measured)

    func testDragDownAtScrollTopMovesTheSheetNotTheContent() {
        // MEASURED: a scroll view at contentOffset 0 inside a sheet gives a
        // downward drag to the SHEET; contentOffset stays at 0.
        let s = present(scrollContent: true)
        drag(s.window, from: 300, travel: 200, hold: 0, lift: false)
        XCTAssertEqual(s.sheet.dragOffset, 190, accuracy: 0.001)
        XCTAssertEqual(s.scroll!.contentOffset.y, 0, accuracy: 0.001)
    }

    func testDragUpScrollsTheContentAndLeavesTheSheet() {
        // MEASURED: the mirror case — the content scrolls by travel − 10 and
        // the sheet does not move.
        let s = present(scrollContent: true)
        var t = 0.0
        s.window.sendTouch(.began, at: CGPoint(x: 196, y: 500), timestamp: t)
        for i in 1...50 {
            t += 0.016
            s.window.sendTouch(.moved, at: CGPoint(x: 196, y: 500 - CGFloat(i) * 4),
                               timestamp: t)
        }
        XCTAssertEqual(s.scroll!.contentOffset.y, 190, accuracy: 0.001)
        XCTAssertEqual(s.sheet.dragOffset, 0, accuracy: 0.001)
        XCTAssertEqual(s.sheet.frame.minY, 59, accuracy: 0.001)
    }

    func testDragDownWhenScrolledBelongsToTheContent() {
        let s = present(scrollContent: true)
        s.scroll!.contentOffset = CGPoint(x: 0, y: 600)
        drag(s.window, from: 300, travel: 200, hold: 0, lift: false)
        XCTAssertEqual(s.sheet.dragOffset, 0, "the sheet must stay put")
        XCTAssertEqual(s.scroll!.contentOffset.y, 410, accuracy: 0.001)
    }
}

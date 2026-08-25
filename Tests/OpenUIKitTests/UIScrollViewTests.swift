// UIScrollView tests (M7.5): deterministic physics unit tests (closed-form
// deceleration / rubber-band / bounce spring per docs/APP_FEEL.md) plus
// touch-pipeline integration (1:1 tracking, ~100 ms release velocity,
// delaysContentTouches, touchesShouldCancel) driven through UIWindow with
// synthetic timestamps — no wall clock anywhere.
import XCTest
import Foundation
@testable import OpenUIKit

// XCTest re-exports Foundation/CoreGraphics on Darwin; pin the portable types.
private typealias CGFloat = OpenUIKit.CGFloat
private typealias CGPoint = OpenUIKit.CGPoint
private typealias CGSize = OpenUIKit.CGSize
private typealias CGRect = OpenUIKit.CGRect

// MARK: - Closed-form physics

final class ScrollPhysicsTests: XCTestCase {

    /// v(t) = v0·0.998^t_ms; x(t) uses the MEASURED per-millisecond
    /// geometric-sum distance factor F = r/(1−r)/1000 = 0.499 (see
    /// golden/scroll_traces + docs/APP_FEEL.md), evaluated independently
    /// with Foundation's pow/log.
    func testDecelerationMatchesClosedForm() {
        let v0: CGFloat = 1200
        let F = 0.998 / (1000 * (1 - 0.998))
        XCTAssertEqual(F, 0.499, accuracy: 1e-12)
        for t in stride(from: 0.05, through: 1.5, by: 0.05) {
            let expectedV = 1200 * pow(0.998, 1000 * t)
            let expectedX = 1200 * F * (1 - pow(0.998, 1000 * t))
            XCTAssertEqual(Double(UIScrollPhysics.decelVelocity(v0: v0, at: t)),
                           expectedV, accuracy: 1e-6)
            XCTAssertEqual(Double(UIScrollPhysics.decelOffset(x0: 0, v0: v0, at: t)),
                           expectedX, accuracy: 1e-6)
        }
    }

    func testDecelerationStopsBelowThreshold() {
        let v0: CGFloat = 1000
        let dur = UIScrollPhysics.decelDuration(v0: v0)
        // v decays to exactly the 10 pt/s stop threshold at `dur`
        // (MEASURED: UIKit never delivers the sub-10 pt/s tail).
        XCTAssertEqual(Double(UIScrollPhysics.decelVelocity(v0: v0, at: dur)),
                       10, accuracy: 1e-9)
        // Total travel of a 1000 pt/s flick: (1000 − 10)·0.499 = 494.01 pt.
        let total = Double(UIScrollPhysics.decelTargetOffset(x0: 0, v0: v0))
        XCTAssertEqual(total, (1000 - 10) * 0.499, accuracy: 1e-6)
    }

    func testDecelerationCrossingTimeIsExact() throws {
        // Starting at 80 with v = 500 toward a boundary at 100.
        let tc = try XCTUnwrap(
            UIScrollPhysics.decelCrossingTime(x0: 80, v0: 500, boundary: 100))
        XCTAssertEqual(Double(UIScrollPhysics.decelOffset(x0: 80, v0: 500, at: tc)),
                       100, accuracy: 1e-9)
        // A boundary beyond the natural stopping point is never crossed.
        XCTAssertNil(UIScrollPhysics.decelCrossingTime(x0: 0, v0: 500, boundary: 400))
        // Moving away from the boundary: no crossing.
        XCTAssertNil(UIScrollPhysics.decelCrossingTime(x0: 80, v0: -500, boundary: 100))
    }

    /// Apple's rubber-band formula with c = 0.55:
    /// (1 − 1/(c·|d|/dim + 1)) · dim · sign(d).
    func testRubberBandFormulaValues() {
        let dim: CGFloat = 280
        for d in [CGFloat(1), 10, 50, 120, 400, 5000] {
            let expected = (1 - 1 / (0.55 * d / dim + 1)) * dim
            XCTAssertEqual(Double(UIScrollPhysics.rubberBand(d, dimension: dim)),
                           Double(expected), accuracy: 1e-9)
            // Odd symmetry.
            XCTAssertEqual(Double(UIScrollPhysics.rubberBand(-d, dimension: dim)),
                           -Double(expected), accuracy: 1e-9)
            // Banded displacement never exceeds the view dimension.
            XCTAssertLessThan(expected, dim)
        }
        XCTAssertEqual(UIScrollPhysics.rubberBand(0, dimension: dim), 0)
        // Spot value: 60 pt past the edge of a 300 pt viewport → 29.729….
        XCTAssertEqual(Double(UIScrollPhysics.rubberBand(60, dimension: 300)),
                       0.55 * 60 * 300 / (0.55 * 60 + 300), accuracy: 1e-9)
    }

    /// The bounce has TWO measured regimes (docs/APP_FEEL.md): released
    /// from rest it is an overdamped spring (λ = 9.0 / 46.0 per second);
    /// entered with velocity it is critically damped with ω = 11.0.
    func testBounceSpringRegimes() {
        XCTAssertEqual(UIScrollPhysics.bounceOmega, 11.0)
        XCTAssertEqual(UIScrollPhysics.bounceRestLambdaSlow, 9.0)
        XCTAssertEqual(UIScrollPhysics.bounceRestLambdaFast, 46.0)

        let x0: CGFloat = 40
        // Rest release (v0 = 0): overdamped two-exponential, checked against
        // an independent evaluation; monotonic decay; the tail decays at the
        // slow rate (settles at ~x0·e^(−9t)·λ2/(λ2−λ1)).
        let l1 = 9.0, l2 = 46.0
        let A = Double(x0) * l2 / (l2 - l1)
        let B = Double(x0) - A
        var prev = Double(x0)
        for t in stride(from: 0.02, through: 0.8, by: 0.02) {
            let expected = A * exp(-l1 * t) + B * exp(-l2 * t)
            let d = Double(UIScrollPhysics.springDisplacement(x0: x0, v0: 0, at: t))
            XCTAssertEqual(d, expected, accuracy: 1e-9)
            XCTAssertGreaterThan(d, 0)
            XCTAssertLessThan(d, prev)
            prev = d
        }
        // The measured zero-velocity bounce-back settles below 1 pt from a
        // 235 pt overscroll in ~0.63 s (oracle: 0.61 s, gate 10%).
        let big: CGFloat = 235
        XCTAssertLessThan(UIScrollPhysics.springDisplacement(x0: big, v0: 0, at: 0.65), 1)
        XCTAssertGreaterThan(UIScrollPhysics.springDisplacement(x0: big, v0: 0, at: 0.55), 1)

        // With velocity: the analytic critically-damped solution at ω = 11.
        let w = UIScrollPhysics.bounceOmega
        let v0: CGFloat = -300
        for t in stride(from: 0.02, through: 0.6, by: 0.02) {
            let b = Double(v0) + w * Double(x0)
            let expected = (Double(x0) + b * t) * exp(-w * t)
            XCTAssertEqual(Double(UIScrollPhysics.springDisplacement(x0: x0, v0: v0, at: t)),
                           expected, accuracy: 1e-9)
        }
    }

    /// Deceleration into an edge → bounce carrying velocity: peak overshoot
    /// of the carried-velocity spring is v/(ω·e), at t = 1/ω.
    func testBounceCarriesReleaseVelocity() {
        let v0: CGFloat = 800
        let w = UIScrollPhysics.bounceOmega
        let tPeak = 1 / w
        let peak = Double(UIScrollPhysics.springDisplacement(x0: 0, v0: v0, at: tPeak))
        XCTAssertEqual(peak, Double(v0) / (w * M_E), accuracy: 1e-9)
        // Velocity is zero at the peak, negative after.
        XCTAssertEqual(Double(UIScrollPhysics.springVelocity(x0: 0, v0: v0, at: tPeak)),
                       0, accuracy: 1e-9)
        XCTAssertLessThan(UIScrollPhysics.springVelocity(x0: 0, v0: v0, at: tPeak + 0.05), 0)
    }
}

// MARK: - Interaction (window-driven, deterministic timestamps)

final class UIScrollViewInteractionTests: XCTestCase {

    override func setUp() {
        super.setUp()
        TextTestSupport.configureResourceRoot()
        UITraitCollection.current = UITraitCollection(userInterfaceStyle: .light,
                                                      displayScale: 2)
        OpenUIKitRuntime.animationTime = 0
    }

    private func makeScrollSetup(contentHeight: CGFloat = 900,
                                 contentWidth: CGFloat = 200)
        -> (window: UIWindow, sv: UIScrollView) {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 200, height: 300))
        let sv = UIScrollView(frame: CGRect(x: 0, y: 0, width: 200, height: 300))
        sv.contentSize = CGSize(width: contentWidth, height: contentHeight)
        window.addSubview(sv)
        window.layoutIfNeeded()
        return (window, sv)
    }

    /// Drag upward at constant 500 pt/s: down, 10 moves of −10 pt every
    /// 20 ms, release. Recognition eats the first ~10 pt (activation slop);
    /// afterwards tracking is 1:1.
    private func flick(_ window: UIWindow, from p0: CGPoint = CGPoint(x: 100, y: 280),
                       steps: Int = 10, dy: CGFloat = -10, dt: Double = 0.02) -> Double {
        window.sendTouch(.began, at: p0, timestamp: 0)
        var t = 0.0
        for k in 1...steps {
            t = dt * Double(k)
            window.sendTouch(.moved, at: CGPoint(x: p0.x, y: p0.y + dy * CGFloat(k)),
                             timestamp: t)
        }
        window.sendTouch(.ended, at: CGPoint(x: p0.x, y: p0.y + dy * CGFloat(steps)),
                         timestamp: t + 0.01)
        return t
    }

    func testDragTracksOneToOne() {
        let (window, sv) = makeScrollSetup()
        window.sendTouch(.began, at: CGPoint(x: 100, y: 200), timestamp: 0)
        // 50 pt move: recognition (slop) happens inside this move; tracking
        // baseline resets at the recognition point.
        window.sendTouch(.moved, at: CGPoint(x: 100, y: 150), timestamp: 0.05)
        let afterRecognition = sv.contentOffset.y
        // Every point of further movement maps 1:1 onto the offset.
        window.sendTouch(.moved, at: CGPoint(x: 100, y: 100), timestamp: 0.1)
        XCTAssertEqual(Double(sv.contentOffset.y - afterRecognition), 50, accuracy: 1e-9)
        window.sendTouch(.moved, at: CGPoint(x: 100, y: 137), timestamp: 0.15)
        XCTAssertEqual(Double(sv.contentOffset.y - afterRecognition), 13, accuracy: 1e-9)
        XCTAssertTrue(sv.isDragging)
    }

    func testFlickDecelerationFollowsClosedForm() {
        let (window, sv) = makeScrollSetup()
        let tEnd = flick(window)  // uniform 500 pt/s upward
        XCTAssertTrue(sv.isDecelerating)
        let x0 = sv.contentOffset.y
        // 100 pt travel − exactly the 10 pt slop (measured UIKit behavior).
        XCTAssertEqual(Double(x0), 90, accuracy: 1e-9)

        // The trailing ~100 ms of samples are exactly 500 pt/s. The
        // animation clock starts at the LIFT event (tEnd + 0.01).
        for dt in [0.05, 0.15, 0.3, 0.6] {
            window.tick(timestamp: tEnd + 0.01 + dt)
            let expected = UIScrollPhysics.decelOffset(x0: x0, v0: 500, at: dt)
            XCTAssertEqual(Double(sv.contentOffset.y), Double(expected), accuracy: 1e-6,
                           "offset at +\(dt)s")
        }
        // Far future: settles exactly at the natural stopping point, done.
        window.tick(timestamp: 10)
        XCTAssertEqual(Double(sv.contentOffset.y),
                       Double(UIScrollPhysics.decelTargetOffset(x0: x0, v0: 500)),
                       accuracy: 1e-6)
        XCTAssertFalse(sv.isDecelerating)
    }

    func testReleaseVelocityUsesTrailingWindow() {
        // Slow (100 pt/s) for 0.3 s, then fast (1000 pt/s) for 0.1 s:
        // release velocity must reflect only the trailing ~100 ms.
        let (window, sv) = makeScrollSetup()
        window.sendTouch(.began, at: CGPoint(x: 100, y: 290), timestamp: 0)
        var y: CGFloat = 290
        var t = 0.0
        for k in 1...15 {  // 100 pt/s: −2 pt per 20 ms
            t = 0.02 * Double(k); y -= 2
            window.sendTouch(.moved, at: CGPoint(x: 100, y: y), timestamp: t)
        }
        for _ in 1...5 {   // 1000 pt/s: −20 pt per 20 ms
            t += 0.02; y -= 20
            window.sendTouch(.moved, at: CGPoint(x: 100, y: y), timestamp: t)
        }
        let x0 = sv.contentOffset.y
        window.sendTouch(.ended, at: CGPoint(x: 100, y: y), timestamp: t + 0.005)
        window.tick(timestamp: t + 0.005 + 0.2)  // decel starts at the lift
        let expected = UIScrollPhysics.decelOffset(x0: x0, v0: 1000, at: 0.2)
        XCTAssertEqual(Double(sv.contentOffset.y), Double(expected), accuracy: 1e-6,
                       "trailing-window velocity should be exactly 1000 pt/s")
    }

    func testDecelerationIntoEdgeBounces() throws {
        // Content 400 in a 300 viewport → max offset 100. The 500 pt/s
        // flick reaches the edge and bounces past it with carried velocity.
        let (window, sv) = makeScrollSetup(contentHeight: 400)
        let tEnd = flick(window)
        let x0 = sv.contentOffset.y     // 90
        let t0 = tEnd + 0.01            // animation clock starts at the lift
        let tc = try XCTUnwrap(
            UIScrollPhysics.decelCrossingTime(x0: x0, v0: 500, boundary: 100))
        let vc = UIScrollPhysics.decelVelocity(v0: 500, at: tc)

        // Shortly after the crossing the content is PAST the edge…
        let peakT = 1 / UIScrollPhysics.bounceOmega
        window.tick(timestamp: t0 + tc + peakT)
        let overshoot = Double(sv.contentOffset.y) - 100
        XCTAssertEqual(overshoot, Double(vc) / (UIScrollPhysics.bounceOmega * M_E),
                       accuracy: 1e-6, "peak overshoot carries the edge velocity")
        XCTAssertGreaterThan(overshoot, 1)
        // …and settles exactly on the boundary.
        window.tick(timestamp: t0 + tc + 2)
        XCTAssertEqual(Double(sv.contentOffset.y), 100, accuracy: 1e-9)
        XCTAssertFalse(sv.isDecelerating)
    }

    func testDragPastEdgeRubberBands() {
        let (window, sv) = makeScrollSetup()
        // At the top, drag DOWN 60 pt past recognition: the offset goes
        // negative through Apple's rubber-band formula (dim = 300).
        window.sendTouch(.began, at: CGPoint(x: 100, y: 100), timestamp: 0)
        window.sendTouch(.moved, at: CGPoint(x: 100, y: 120), timestamp: 0.05)
        window.sendTouch(.moved, at: CGPoint(x: 100, y: 180), timestamp: 0.1)
        // 80 pt of finger travel − 10 pt slop = 70 pt raw overshoot.
        let banded = UIScrollPhysics.rubberBand(-70, dimension: 300)
        XCTAssertEqual(Double(sv.contentOffset.y), Double(banded), accuracy: 1e-9)
        XCTAssertEqual(Double(sv.contentOffset.y), -34.121, accuracy: 0.001)

        // Release: critically-damped bounce back to 0, carrying velocity.
        window.sendTouch(.ended, at: CGPoint(x: 100, y: 180), timestamp: 0.12)
        XCTAssertTrue(sv.isDecelerating)
        // The outward velocity pushes further past the edge first…
        window.tick(timestamp: 0.15)
        XCTAssertLessThan(sv.contentOffset.y, banded)
        // …then the spring settles exactly at the boundary.
        window.tick(timestamp: 1.5)
        XCTAssertEqual(Double(sv.contentOffset.y), 0, accuracy: 1e-9)
        XCTAssertFalse(sv.isDecelerating)
    }

    func testHorizontalDragOnVerticalContentDoesNotScroll() {
        let (window, sv) = makeScrollSetup()          // no horizontal overflow
        window.sendTouch(.began, at: CGPoint(x: 60, y: 150), timestamp: 0)
        window.sendTouch(.moved, at: CGPoint(x: 100, y: 150), timestamp: 0.05)
        window.sendTouch(.moved, at: CGPoint(x: 140, y: 150), timestamp: 0.1)
        window.sendTouch(.ended, at: CGPoint(x: 140, y: 150), timestamp: 0.15)
        XCTAssertEqual(sv.contentOffset.x, 0)
        XCTAssertEqual(sv.contentOffset.y, 0)
        XCTAssertFalse(sv.isDecelerating)
    }

    // MARK: Indicators

    func testIndicatorFlashesAndFadesAfterSettle() throws {
        let (window, sv) = makeScrollSetup()
        XCTAssertNil(sv.verticalIndicator, "indicators are lazy — none at rest")
        let tEnd = flick(window)
        let bar = try XCTUnwrap(sv.verticalIndicator)
        XCTAssertEqual(bar.alpha, 1, "visible while decelerating")
        // 2.5 pt bar, 3 pt inset from the trailing edge.
        XCTAssertEqual(Double(bar.frame.width), 2.5, accuracy: 1e-9)
        XCTAssertEqual(Double(bar.frame.maxX - sv.contentOffset.x), 200 - 3,
                       accuracy: 1e-9)
        // Pinned to the visible rect while the content scrolls.
        window.tick(timestamp: tEnd + 0.2)
        XCTAssertEqual(Double(bar.frame.minY - sv.contentOffset.y),
                       Double(3 + (300 - 2 * 3 - bar.frame.height)
                              * (sv.contentOffset.y / 600)), accuracy: 1e-6)
        // Settle → 0.4 s fade recorded on the UIView.animate clock.
        window.tick(timestamp: 10)
        XCTAssertEqual(bar.alpha, 0, "model alpha 0 after fade begins")
        let fade = try XCTUnwrap(bar.animations.first { $0.property == .alpha })
        XCTAssertEqual(fade.duration, 0.4, accuracy: 1e-9)
    }

    // MARK: delaysContentTouches / touchesShouldCancel

    private func makeButtonSetup()
        -> (window: UIWindow, sv: UIScrollView, button: UIButton, log: Log) {
        let (window, sv) = makeScrollSetup()
        let button = UIButton(type: .system)
        button.setTitle("Tap", for: .normal)
        button.frame = CGRect(x: 20, y: 20, width: 120, height: 44)
        sv.addSubview(button)
        window.layoutIfNeeded()
        let log = Log()
        button.addTarget(for: .touchDown) { _, _ in log.events.append("down") }
        button.addTarget(for: .touchUpInside) { _, _ in log.events.append("upInside") }
        button.addTarget(for: .touchCancel) { _, _ in log.events.append("cancel") }
        return (window, sv, button, log)
    }

    final class Log { var events: [String] = [] }

    func testQuickTapDeliversDelayedTouchOnLift() {
        let (window, _, button, log) = makeButtonSetup()
        window.sendTouch(.began, at: CGPoint(x: 60, y: 40), timestamp: 0)
        XCTAssertFalse(button.isHighlighted, "touch-down is held ~150 ms")
        XCTAssertEqual(log.events, [])
        // Lift before the delay: began flushes, then the up lands — the tap
        // still works (UIKit lets the highlight paint on the way out).
        window.sendTouch(.ended, at: CGPoint(x: 60, y: 40), timestamp: 0.05)
        XCTAssertEqual(log.events, ["down", "upInside"])
    }

    func testHeldTouchDeliversAfterContentTouchDelay() {
        let (window, _, button, log) = makeButtonSetup()
        window.sendTouch(.began, at: CGPoint(x: 60, y: 40), timestamp: 0)
        window.tick(timestamp: 0.1)
        XCTAssertFalse(button.isHighlighted)
        window.tick(timestamp: 0.16)   // past the ~150 ms content-touch delay
        XCTAssertTrue(button.isHighlighted)
        XCTAssertEqual(log.events, ["down"])
        window.sendTouch(.ended, at: CGPoint(x: 60, y: 40), timestamp: 0.3)
        XCTAssertEqual(log.events, ["down", "upInside"])
    }

    func testDragDuringDelayScrollsWithoutTouchingContent() {
        let (window, sv, button, log) = makeButtonSetup()
        window.sendTouch(.began, at: CGPoint(x: 60, y: 40), timestamp: 0)
        window.sendTouch(.moved, at: CGPoint(x: 60, y: 20), timestamp: 0.05)
        window.sendTouch(.moved, at: CGPoint(x: 60, y: 0), timestamp: 0.1)
        XCTAssertGreaterThan(sv.contentOffset.y, 0, "pan claimed the touch")
        XCTAssertEqual(log.events, [], "content never saw the touch")
        XCTAssertFalse(button.isHighlighted)
        window.sendTouch(.ended, at: CGPoint(x: 60, y: 0), timestamp: 0.15)
        XCTAssertEqual(log.events, [])
    }

    func testScrollCancelsDeliveredContentTouch() {
        let (window, sv, button, log) = makeButtonSetup()
        window.sendTouch(.began, at: CGPoint(x: 60, y: 40), timestamp: 0)
        window.tick(timestamp: 0.16)
        XCTAssertTrue(button.isHighlighted, "delivered after the delay")
        // Now drag: touchesShouldCancel (true for controls in modern UIKit)
        // lets the pan cancel the button's tracking and scroll.
        window.sendTouch(.moved, at: CGPoint(x: 60, y: 20), timestamp: 0.2)
        window.sendTouch(.moved, at: CGPoint(x: 60, y: 0), timestamp: 0.25)
        XCTAssertFalse(button.isHighlighted)
        XCTAssertEqual(log.events, ["down", "cancel"])
        XCTAssertGreaterThan(sv.contentOffset.y, 0)
    }

    // MARK: Early content-touch claim (row highlight vs finger travel)

    /// Vertical travel past `contentTouchCancelDistance` cancels the content
    /// touch in the SAME event, before the pan crosses its 10 pt slop: the
    /// highlight is already fading when the content starts to move.
    func testVerticalTravelCancelsHighlightBeforeThePanBegins() {
        let (window, sv, button, log) = makeButtonSetup()
        window.sendTouch(.began, at: CGPoint(x: 60, y: 40), timestamp: 0)
        window.tick(timestamp: 0.16)
        XCTAssertTrue(button.isHighlighted)

        // 7 pt: past the 5 pt claim distance, still inside the 10 pt slop.
        window.sendTouch(.moved, at: CGPoint(x: 60, y: 33), timestamp: 0.2)
        XCTAssertFalse(button.isHighlighted, "highlight must cancel immediately")
        XCTAssertEqual(log.events, ["down", "cancel"])
        XCTAssertEqual(sv.panGestureRecognizer.state, .possible,
                       "the pan keeps its own slop — nothing scrolls yet")
        XCTAssertEqual(sv.contentOffset.y, 0)

        // The claim does not break the pan: it begins on the next move,
        // which applies its travel minus exactly the 10 pt slop (measured
        // UIKit behavior), and tracks 1:1 from there.
        window.sendTouch(.moved, at: CGPoint(x: 60, y: 10), timestamp: 0.25)
        XCTAssertEqual(sv.panGestureRecognizer.state, .began)
        XCTAssertEqual(Double(sv.contentOffset.y), 20, accuracy: 1e-9)
        window.sendTouch(.moved, at: CGPoint(x: 60, y: 0), timestamp: 0.3)
        XCTAssertEqual(Double(sv.contentOffset.y), 30, accuracy: 1e-9)
        window.sendTouch(.ended, at: CGPoint(x: 60, y: 0), timestamp: 0.3)
        XCTAssertEqual(log.events, ["down", "cancel"], "no tap fires")
    }

    /// A finger that barely moves is still a press: the highlight stays and
    /// the tap fires on lift.
    func testTinyTravelKeepsTheHighlightAndTaps() {
        let (window, sv, button, log) = makeButtonSetup()
        window.sendTouch(.began, at: CGPoint(x: 60, y: 40), timestamp: 0)
        window.tick(timestamp: 0.16)
        window.sendTouch(.moved, at: CGPoint(x: 60, y: 37), timestamp: 0.2)
        XCTAssertTrue(button.isHighlighted, "3 pt is inside the claim distance")
        XCTAssertEqual(sv.contentOffset.y, 0)
        window.sendTouch(.ended, at: CGPoint(x: 60, y: 37), timestamp: 0.25)
        XCTAssertEqual(log.events, ["down", "upInside"])
    }

    /// Travel along a NON-scrollable axis is not a drag: a horizontal wiggle
    /// in a vertical scroll view keeps the press.
    func testHorizontalTravelKeepsTheHighlightInAVerticalScrollView() {
        let (window, sv, button, log) = makeButtonSetup()
        XCTAssertFalse(sv.dragsX, "fixture scrolls vertically only")
        window.sendTouch(.began, at: CGPoint(x: 60, y: 40), timestamp: 0)
        window.tick(timestamp: 0.16)
        window.sendTouch(.moved, at: CGPoint(x: 68, y: 40), timestamp: 0.2)
        XCTAssertTrue(button.isHighlighted)
        XCTAssertEqual(log.events, ["down"])
    }

    /// The same claim applies while delaysContentTouches still holds the
    /// touch: the row never highlights at all, and (as before) a dropped
    /// pending touch gets no touchesCancelled because it was never delivered.
    func testTravelDuringTheDelayDropsTheHeldTouch() {
        let (window, sv, button, log) = makeButtonSetup()
        window.sendTouch(.began, at: CGPoint(x: 60, y: 40), timestamp: 0)
        window.sendTouch(.moved, at: CGPoint(x: 60, y: 33), timestamp: 0.05)
        XCTAssertEqual(sv.panGestureRecognizer.state, .possible)
        // Past the content-touch delay the held began must NOT flush.
        window.tick(timestamp: 0.2)
        XCTAssertFalse(button.isHighlighted)
        XCTAssertEqual(log.events, [], "content never saw the touch")
    }

    /// touchesShouldCancel(in:) == false blocks the early claim too — the
    /// control keeps tracking through any amount of travel.
    func testEarlyClaimRespectsTouchesShouldCancel() {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 200, height: 300))
        let sv = NoCancelScrollView(frame: CGRect(x: 0, y: 0, width: 200, height: 300))
        sv.contentSize = CGSize(width: 200, height: 900)
        window.addSubview(sv)
        let button = UIButton(type: .system)
        button.setTitle("Tap", for: .normal)
        button.frame = CGRect(x: 20, y: 20, width: 120, height: 44)
        sv.addSubview(button)
        window.layoutIfNeeded()

        window.sendTouch(.began, at: CGPoint(x: 60, y: 40), timestamp: 0)
        window.tick(timestamp: 0.16)
        window.sendTouch(.moved, at: CGPoint(x: 60, y: 33), timestamp: 0.2)
        XCTAssertTrue(button.isHighlighted)
        XCTAssertTrue(button.isTracking)
    }

    final class NoCancelScrollView: UIScrollView {
        override func touchesShouldCancel(in view: UIView) -> Bool { false }
    }

    func testTouchesShouldCancelFalseBlocksTheScroll() {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 200, height: 300))
        let sv = NoCancelScrollView(frame: CGRect(x: 0, y: 0, width: 200, height: 300))
        sv.contentSize = CGSize(width: 200, height: 900)
        window.addSubview(sv)
        let button = UIButton(type: .system)
        button.setTitle("Tap", for: .normal)
        button.frame = CGRect(x: 20, y: 20, width: 120, height: 44)
        sv.addSubview(button)
        window.layoutIfNeeded()

        window.sendTouch(.began, at: CGPoint(x: 60, y: 40), timestamp: 0)
        window.tick(timestamp: 0.16)
        XCTAssertTrue(button.isHighlighted)
        window.sendTouch(.moved, at: CGPoint(x: 60, y: 20), timestamp: 0.2)
        window.sendTouch(.moved, at: CGPoint(x: 60, y: 0), timestamp: 0.25)
        // The pan must NOT steal the delivered control touch.
        XCTAssertEqual(sv.contentOffset.y, 0)
        XCTAssertTrue(button.isTracking)
    }

    func testTouchCatchStopsDeceleration() {
        let (window, sv) = makeScrollSetup()
        let tEnd = flick(window)
        window.tick(timestamp: tEnd + 0.2)
        XCTAssertTrue(sv.isDecelerating)
        let caughtAt = sv.contentOffset.y
        // Finger down mid-deceleration: the scroll freezes where it is and
        // the touch is consumed (never reaches content).
        window.sendTouch(.began, at: CGPoint(x: 100, y: 150), timestamp: tEnd + 0.25)
        XCTAssertFalse(sv.isDecelerating)
        window.tick(timestamp: tEnd + 1)
        XCTAssertEqual(Double(sv.contentOffset.y), Double(caughtAt), accuracy: 1e-9)
        window.sendTouch(.ended, at: CGPoint(x: 100, y: 150), timestamp: tEnd + 1.05)
        window.tick(timestamp: tEnd + 2)
        XCTAssertEqual(Double(sv.contentOffset.y), Double(caughtAt), accuracy: 1e-9)
    }

    // MARK: Rendering (bounds.origin drives sublayer scroll)

    func testBothCompositorsRenderScrolledContent() {
        let root = UIView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        let sv = UIScrollView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        sv.backgroundColor = UIColor(red: 1, green: 1, blue: 1, alpha: 1)
        sv.contentSize = CGSize(width: 100, height: 200)
        let red = UIView(frame: CGRect(x: 0, y: 50, width: 100, height: 50))
        red.backgroundColor = UIColor(red: 1, green: 0, blue: 0, alpha: 1)
        sv.addSubview(red)
        sv.contentOffset = CGPoint(x: 0, y: 50)
        root.addSubview(sv)
        root.layoutIfNeeded()

        func probe(_ bmp: Bitmap, _ x: Int, _ y: Int) -> [UInt8] {
            let o = (y * bmp.width + x) * 4
            return [bmp.pixels[o], bmp.pixels[o + 1], bmp.pixels[o + 2]]
        }
        let savedBackend = OpenUIKitRuntime.renderBackend
        let savedCompositor = OpenUIKitRuntime.compositor
        defer {
            OpenUIKitRuntime.renderBackend = savedBackend
            OpenUIKitRuntime.compositor = savedCompositor
        }
        for (backend, compositor) in [(RenderBackend.quartz, RenderCompositor.layers),
                                      (RenderBackend.quartz, RenderCompositor.renderPass),
                                      (RenderBackend.swift, RenderCompositor.renderPass)] {
            OpenUIKitRuntime.renderBackend = backend
            OpenUIKitRuntime.compositor = compositor
            let bmp = UIRenderer.render(root, scale: 1)
            // Offset 50: the red band (content y 50–100) fills the TOP half.
            XCTAssertEqual(probe(bmp, 50, 10), [255, 0, 0],
                           "\(backend)/\(compositor)")
            // Bottom half shows the white background.
            XCTAssertEqual(probe(bmp, 50, 90), [255, 255, 255],
                           "\(backend)/\(compositor)")
        }
    }
}

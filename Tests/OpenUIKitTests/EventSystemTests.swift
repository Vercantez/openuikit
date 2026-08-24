// Event-module tests (M7): hit testing / coordinate conversion, UIWindow
// touch routing, UIControl tracking + target-action, and the gesture
// recognizer state machines — all with synthetic, deterministic timestamps
// (no wall clock anywhere in the event path).
import XCTest
import Foundation
@testable import OpenUIKit

// XCTest re-exports Foundation/CoreGraphics on Darwin; pin the portable types.
private typealias CGFloat = OpenUIKit.CGFloat
private typealias CGPoint = OpenUIKit.CGPoint
private typealias CGSize = OpenUIKit.CGSize
private typealias CGRect = OpenUIKit.CGRect
private typealias CGAffineTransform = OpenUIKit.CGAffineTransform

/// Records every UIResponder touch entry point it receives.
private final class TouchRecorder: UIView {
    var log: [String] = []
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        log.append("began:\(touches.count)")
    }
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        log.append("moved:\(touches.count)")
    }
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        log.append("ended:\(touches.count)")
    }
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        log.append("cancelled:\(touches.count)")
    }
}

final class HitTestConvertTests: XCTestCase {
    func testConvertRoundTripThroughNestedViews() {
        let root = UIView(frame: CGRect(x: 0, y: 0, width: 400, height: 300))
        let a = UIView(frame: CGRect(x: 50, y: 40, width: 200, height: 150))
        let b = UIView(frame: CGRect(x: 10, y: 20, width: 100, height: 80))
        root.addSubview(a)
        a.addSubview(b)
        let p = CGPoint(x: 30, y: 40)      // in b
        let inRoot = b.convert(p, to: root)
        XCTAssertEqual(inRoot.x, 50 + 10 + 30, accuracy: 1e-9)
        XCTAssertEqual(inRoot.y, 40 + 20 + 40, accuracy: 1e-9)
        let back = b.convert(inRoot, from: root)
        XCTAssertEqual(back.x, p.x, accuracy: 1e-9)
        XCTAssertEqual(back.y, p.y, accuracy: 1e-9)
    }

    func testConvertWithRotationAboutCenter() {
        let root = UIView(frame: CGRect(x: 0, y: 0, width: 400, height: 300))
        let v = UIView(frame: CGRect(x: 100, y: 100, width: 80, height: 60))
        root.addSubview(v)
        v.transform = CGAffineTransform(rotationAngle: .pi / 2)
        // The view's center (140, 130) maps to its bounds middle (40, 30).
        let mid = v.convert(CGPoint(x: 140, y: 130), from: root)
        XCTAssertEqual(mid.x, 40, accuracy: 1e-9)
        XCTAssertEqual(mid.y, 30, accuracy: 1e-9)
        // A point 10pt right of center in root space is 10pt "down" less
        // rotation… verify by round trip instead of hand-derivation.
        let q = CGPoint(x: 150, y: 130)
        let there = v.convert(q, from: root)
        let back = v.convert(there, to: root)
        XCTAssertEqual(back.x, q.x, accuracy: 1e-9)
        XCTAssertEqual(back.y, q.y, accuracy: 1e-9)
    }

    func testPointInsideEdgeSemantics() {
        let v = UIView(frame: CGRect(x: 0, y: 0, width: 100, height: 50))
        XCTAssertTrue(v.point(inside: CGPoint(x: 0, y: 0), with: nil))     // min inclusive
        XCTAssertTrue(v.point(inside: CGPoint(x: 99.99, y: 49.99), with: nil))
        XCTAssertFalse(v.point(inside: CGPoint(x: 100, y: 25), with: nil)) // max exclusive
        XCTAssertFalse(v.point(inside: CGPoint(x: 50, y: 50), with: nil))
    }

    func testHitTestFrontToBackAndPruning() {
        let root = UIView(frame: CGRect(x: 0, y: 0, width: 300, height: 200))
        let back = UIView(frame: CGRect(x: 20, y: 20, width: 100, height: 100))
        let front = UIView(frame: CGRect(x: 60, y: 60, width: 100, height: 100))
        let hidden = UIView(frame: CGRect(x: 200, y: 20, width: 50, height: 50))
        hidden.isHidden = true
        let ghost = UIView(frame: CGRect(x: 200, y: 100, width: 50, height: 50))
        ghost.alpha = 0.005
        let disabled = UIView(frame: CGRect(x: 20, y: 140, width: 80, height: 50))
        disabled.isUserInteractionEnabled = false
        let child = UIView(frame: CGRect(x: 10, y: 10, width: 30, height: 30))
        disabled.addSubview(child)
        for v in [back, front, hidden, ghost, disabled] { root.addSubview(v) }

        XCTAssertTrue(root.hitTest(CGPoint(x: 80, y: 80), with: nil) === front)   // overlap: front wins
        XCTAssertTrue(root.hitTest(CGPoint(x: 30, y: 30), with: nil) === back)
        XCTAssertTrue(root.hitTest(CGPoint(x: 220, y: 30), with: nil) === root)   // hidden pruned
        XCTAssertTrue(root.hitTest(CGPoint(x: 220, y: 120), with: nil) === root)  // alpha < 0.01 pruned
        XCTAssertTrue(root.hitTest(CGPoint(x: 40, y: 155), with: nil) === root)   // disabled subtree pruned
        XCTAssertNil(root.hitTest(CGPoint(x: 400, y: 80), with: nil))             // outside root
    }

    func testSubviewOutsideParentBoundsIsUnreachable() {
        let root = UIView(frame: CGRect(x: 0, y: 0, width: 300, height: 200))
        let parent = UIView(frame: CGRect(x: 20, y: 20, width: 100, height: 100))
        let overflow = UIView(frame: CGRect(x: 80, y: 80, width: 100, height: 100))
        root.addSubview(parent)
        parent.addSubview(overflow)   // spills to (100..200, 100..200) in root
        // Point inside overflow but outside parent: unreachable (regardless
        // of clipsToBounds — oracle-verified in golden/hit_testing).
        XCTAssertTrue(root.hitTest(CGPoint(x: 150, y: 150), with: nil) === root)
        parent.clipsToBounds = false
        XCTAssertTrue(root.hitTest(CGPoint(x: 150, y: 150), with: nil) === root)
        // Point inside both parent and overflow: hits overflow.
        XCTAssertTrue(root.hitTest(CGPoint(x: 110, y: 110), with: nil) === overflow)
    }

    func testLabelAndImageViewFallThrough() {
        let root = UIView(frame: CGRect(x: 0, y: 0, width: 200, height: 100))
        let label = UILabel(frame: CGRect(x: 10, y: 10, width: 100, height: 20))
        label.text = "hi"
        let iv = UIImageView(frame: CGRect(x: 10, y: 50, width: 50, height: 30))
        root.addSubview(label)
        root.addSubview(iv)
        XCTAssertTrue(root.hitTest(CGPoint(x: 30, y: 20), with: nil) === root)
        XCTAssertTrue(root.hitTest(CGPoint(x: 30, y: 60), with: nil) === root)
        label.isUserInteractionEnabled = true
        XCTAssertTrue(root.hitTest(CGPoint(x: 30, y: 20), with: nil) === label)
    }
}

final class WindowTouchRoutingTests: XCTestCase {
    func testTouchDeliveryAndLocations() {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 400, height: 300))
        let rec = TouchRecorder(frame: CGRect(x: 100, y: 100, width: 100, height: 100))
        window.addSubview(rec)

        let t = window.sendTouch(.began, at: CGPoint(x: 150, y: 150), timestamp: 1.0)
        XCTAssertNotNil(t)
        XCTAssertTrue(t!.view === rec)
        XCTAssertEqual(t!.location(in: rec).x, 50, accuracy: 1e-9)
        XCTAssertEqual(t!.timestamp, 1.0)
        window.sendTouch(.moved, at: CGPoint(x: 160, y: 155), timestamp: 1.05)
        XCTAssertEqual(t!.previousLocation(in: rec).x, 50, accuracy: 1e-9)
        XCTAssertEqual(t!.location(in: rec).x, 60, accuracy: 1e-9)
        window.sendTouch(.ended, at: CGPoint(x: 160, y: 155), timestamp: 1.1)
        XCTAssertEqual(rec.log, ["began:1", "moved:1", "ended:1"])
        XCTAssertEqual(t!.phase, .ended)
    }

    func testTapCountAcrossQuickSequentialTaps() {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 400, height: 300))
        let p = CGPoint(x: 50, y: 50)
        let t1 = window.sendTouch(.began, at: p, timestamp: 0)!
        window.sendTouch(.ended, at: p, timestamp: 0.05)
        XCTAssertEqual(t1.tapCount, 1)
        let t2 = window.sendTouch(.began, at: p, timestamp: 0.2)!
        window.sendTouch(.ended, at: p, timestamp: 0.25)
        XCTAssertEqual(t2.tapCount, 2)
        // Too late for the sequence: resets to 1.
        let t3 = window.sendTouch(.began, at: p, timestamp: 2.0)!
        XCTAssertEqual(t3.tapCount, 1)
        // Too far away: resets to 1.
        let t4 = window.sendTouch(.began, at: CGPoint(x: 200, y: 200), timestamp: 2.1)!
        XCTAssertEqual(t4.tapCount, 1)
    }
}

final class UIControlTests: XCTestCase {
    func testTapFiresTouchDownAndUpInsideWithHighlight() {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 400, height: 300))
        let control = UIControl(frame: CGRect(x: 10, y: 10, width: 100, height: 40))
        window.addSubview(control)
        var events: [String] = []
        control.addTarget(for: .touchDown) { c, _ in
            events.append("down hl=\(c.isHighlighted)")
        }
        control.addTarget(for: .touchUpInside) { c, _ in
            events.append("upInside hl=\(c.isHighlighted)")
        }
        control.addTarget(for: .touchUpOutside) { _, _ in events.append("upOutside") }

        window.sendTouch(.began, at: CGPoint(x: 50, y: 30), timestamp: 0)
        XCTAssertTrue(control.isTracking)
        XCTAssertTrue(control.isHighlighted)
        window.sendTouch(.ended, at: CGPoint(x: 52, y: 30), timestamp: 0.1)
        XCTAssertFalse(control.isTracking)
        XCTAssertFalse(control.isHighlighted)
        XCTAssertEqual(events, ["down hl=true", "upInside hl=false"])
    }

    func testDragOutsideAndUpOutside() {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 400, height: 300))
        let control = UIControl(frame: CGRect(x: 10, y: 10, width: 100, height: 40))
        window.addSubview(control)
        var events: [String] = []
        for (e, name): (UIControl.Event, String) in
            [(.touchDragInside, "dragIn"), (.touchDragOutside, "dragOut"),
             (.touchDragEnter, "enter"), (.touchDragExit, "exit"),
             (.touchUpOutside, "upOutside"), (.touchUpInside, "upInside")] {
            control.addTarget(for: e) { _, _ in events.append(name) }
        }
        window.sendTouch(.began, at: CGPoint(x: 50, y: 30), timestamp: 0)
        window.sendTouch(.moved, at: CGPoint(x: 60, y: 30), timestamp: 0.02)  // inside
        window.sendTouch(.moved, at: CGPoint(x: 200, y: 30), timestamp: 0.04) // exit
        XCTAssertFalse(control.isHighlighted)
        window.sendTouch(.moved, at: CGPoint(x: 55, y: 30), timestamp: 0.06)  // re-enter
        XCTAssertTrue(control.isHighlighted)
        window.sendTouch(.moved, at: CGPoint(x: 210, y: 30), timestamp: 0.08) // exit again
        window.sendTouch(.ended, at: CGPoint(x: 210, y: 30), timestamp: 0.1)
        XCTAssertEqual(events, ["dragIn", "dragOut", "exit", "dragIn", "enter",
                                "dragOut", "exit", "upOutside"])
    }

    func testDisabledControlIgnoresTouches() {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 400, height: 300))
        let control = UIControl(frame: CGRect(x: 10, y: 10, width: 100, height: 40))
        control.isEnabled = false
        window.addSubview(control)
        var fired = false
        control.addTarget(for: .allTouchEvents) { _, _ in fired = true }
        // Disabled controls still hit-test (UIKit: isEnabled does not remove
        // them from hit testing) but do not track.
        window.sendTouch(.began, at: CGPoint(x: 50, y: 30), timestamp: 0)
        window.sendTouch(.ended, at: CGPoint(x: 50, y: 30), timestamp: 0.1)
        XCTAssertFalse(fired)
        XCTAssertFalse(control.isTracking)
    }

    func testButtonHighlightDimsTitle() {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 400, height: 300))
        let button = UIButton(type: .system)
        button.setTitle("Tap", for: .normal)
        button.frame = CGRect(x: 10, y: 10, width: 80, height: 40)
        window.addSubview(button)
        let normalAlpha = button.currentTitleColor.cgColor.alpha
        window.sendTouch(.began, at: CGPoint(x: 50, y: 30), timestamp: 0)
        XCTAssertTrue(button.isHighlighted)
        XCTAssertEqual(button.state, [.highlighted])
        XCTAssertEqual(button.currentTitleColor.cgColor.alpha,
                       normalAlpha * 0.2, accuracy: 1e-6)
        window.sendTouch(.ended, at: CGPoint(x: 50, y: 30), timestamp: 0.1)
        XCTAssertFalse(button.isHighlighted)
        XCTAssertEqual(button.currentTitleColor.cgColor.alpha, normalAlpha,
                       accuracy: 1e-6)
    }

    func testSwitchTapTogglesAndFiresValueChanged() {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 400, height: 300))
        let sw = UISwitch()
        sw.frame = CGRect(x: 10, y: 10, width: 0, height: 0)  // forced 63x28
        window.addSubview(sw)
        var changes: [Bool] = []
        sw.addTarget(for: .valueChanged) { c, _ in changes.append((c as! UISwitch).isOn) }

        window.sendTouch(.began, at: CGPoint(x: 40, y: 24), timestamp: 0)
        window.sendTouch(.ended, at: CGPoint(x: 40, y: 24), timestamp: 0.08)
        XCTAssertTrue(sw.isOn)
        XCTAssertNotNil(sw.toggleAnim)          // animated toggle recorded
        XCTAssertEqual(sw.toggleAnim?.fromOn, false)
        window.sendTouch(.began, at: CGPoint(x: 40, y: 24), timestamp: 1.0)
        window.sendTouch(.ended, at: CGPoint(x: 40, y: 24), timestamp: 1.08)
        XCTAssertFalse(sw.isOn)
        XCTAssertEqual(changes, [true, false])
        // Release outside: no toggle.
        window.sendTouch(.began, at: CGPoint(x: 40, y: 24), timestamp: 2.0)
        window.sendTouch(.moved, at: CGPoint(x: 300, y: 200), timestamp: 2.05)
        window.sendTouch(.ended, at: CGPoint(x: 300, y: 200), timestamp: 2.1)
        XCTAssertFalse(sw.isOn)
        XCTAssertEqual(changes, [true, false])
    }
}

final class TapGestureTests: XCTestCase {
    func testSingleTapRecognizes() {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 400, height: 300))
        let v = UIView(frame: CGRect(x: 0, y: 0, width: 200, height: 200))
        window.addSubview(v)
        var states: [UIGestureRecognizer.State] = []
        let tap = UITapGestureRecognizer { states.append($0.state) }
        v.addGestureRecognizer(tap)

        window.sendTouch(.began, at: CGPoint(x: 50, y: 50), timestamp: 0)
        XCTAssertEqual(tap.state, .possible)
        window.sendTouch(.ended, at: CGPoint(x: 52, y: 51), timestamp: 0.08)
        XCTAssertEqual(states, [.ended])
        // Sequence complete: recognizer reset for the next touch.
        XCTAssertEqual(tap.state, .possible)
    }

    func testTapFailsWhenMovedTooFar() {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 400, height: 300))
        let v = UIView(frame: CGRect(x: 0, y: 0, width: 200, height: 200))
        window.addSubview(v)
        var fired = false
        let tap = UITapGestureRecognizer { _ in fired = true }
        v.addGestureRecognizer(tap)

        window.sendTouch(.began, at: CGPoint(x: 50, y: 50), timestamp: 0)
        window.sendTouch(.moved, at: CGPoint(x: 70, y: 50), timestamp: 0.05) // 20pt > 10pt slop
        XCTAssertEqual(tap.state, .failed)
        window.sendTouch(.ended, at: CGPoint(x: 70, y: 50), timestamp: 0.1)
        XCTAssertFalse(fired)
        XCTAssertEqual(tap.state, .possible)  // reset after the sequence
    }

    func testDoubleTapRequiresTwoQuickTaps() {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 400, height: 300))
        let v = UIView(frame: CGRect(x: 0, y: 0, width: 200, height: 200))
        window.addSubview(v)
        var fired = 0
        let tap = UITapGestureRecognizer { _ in fired += 1 }
        tap.numberOfTapsRequired = 2
        v.addGestureRecognizer(tap)

        let p = CGPoint(x: 50, y: 50)
        window.sendTouch(.began, at: p, timestamp: 0)
        window.sendTouch(.ended, at: p, timestamp: 0.05)
        XCTAssertEqual(fired, 0)
        window.sendTouch(.began, at: p, timestamp: 0.2)
        window.sendTouch(.ended, at: p, timestamp: 0.25)
        XCTAssertEqual(fired, 1)
        // A slow second tap does not recognize.
        window.sendTouch(.began, at: p, timestamp: 3.0)
        window.sendTouch(.ended, at: p, timestamp: 3.05)
        window.sendTouch(.began, at: p, timestamp: 4.0)   // > multiTapInterval later
        window.sendTouch(.ended, at: p, timestamp: 4.05)
        XCTAssertEqual(fired, 1)
    }

    func testTapCancelsTouchesInView() {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 400, height: 300))
        let rec = TouchRecorder(frame: CGRect(x: 0, y: 0, width: 200, height: 200))
        window.addSubview(rec)
        let tap = UITapGestureRecognizer()
        rec.addGestureRecognizer(tap)

        window.sendTouch(.began, at: CGPoint(x: 50, y: 50), timestamp: 0)
        window.sendTouch(.ended, at: CGPoint(x: 50, y: 50), timestamp: 0.08)
        // Recognition happens in the same event as the end: the view got
        // began, then cancelled — the ended is never delivered.
        XCTAssertEqual(rec.log, ["began:1", "cancelled:1"])
    }
}

final class PanGestureTests: XCTestCase {
    private func makePan() -> (UIWindow, UIView, UIPanGestureRecognizer,
                               () -> [UIGestureRecognizer.State]) {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 400, height: 300))
        let v = UIView(frame: CGRect(x: 0, y: 0, width: 300, height: 300))
        window.addSubview(v)
        var states: [UIGestureRecognizer.State] = []
        let pan = UIPanGestureRecognizer { states.append($0.state) }
        v.addGestureRecognizer(pan)
        return (window, v, pan, { states })
    }

    func testActivationSlopThenTranslationAndVelocity() {
        let (window, v, pan, states) = makePan()
        window.sendTouch(.began, at: CGPoint(x: 100, y: 100), timestamp: 0)
        XCTAssertEqual(pan.state, .possible)
        window.sendTouch(.moved, at: CGPoint(x: 105, y: 100), timestamp: 0.05)
        XCTAssertEqual(pan.state, .possible)          // 5pt < 10pt slop
        window.sendTouch(.moved, at: CGPoint(x: 120, y: 100), timestamp: 0.1)
        XCTAssertEqual(pan.state, .began)             // 20pt > slop
        XCTAssertEqual(pan.translation(in: v).x, 20, accuracy: 1e-9)
        // velocity from the last move step: 15pt over 0.05s = 300 pt/s
        XCTAssertEqual(pan.velocity(in: v).x, 300, accuracy: 1e-6)
        window.sendTouch(.moved, at: CGPoint(x: 140, y: 110), timestamp: 0.15)
        XCTAssertEqual(pan.state, .changed)
        XCTAssertEqual(pan.translation(in: v).x, 40, accuracy: 1e-9)
        XCTAssertEqual(pan.translation(in: v).y, 10, accuracy: 1e-9)
        pan.setTranslation(.zero, in: v)
        XCTAssertEqual(pan.translation(in: v).x, 0, accuracy: 1e-9)
        window.sendTouch(.moved, at: CGPoint(x: 150, y: 110), timestamp: 0.2)
        XCTAssertEqual(pan.translation(in: v).x, 10, accuracy: 1e-9)
        window.sendTouch(.ended, at: CGPoint(x: 150, y: 110), timestamp: 0.25)
        XCTAssertEqual(states(), [.began, .changed, .changed, .ended])
        XCTAssertEqual(pan.state, .possible)          // reset
    }

    func testPanFailsOnTapLikeSequence() {
        let (window, _, pan, states) = makePan()
        window.sendTouch(.began, at: CGPoint(x: 100, y: 100), timestamp: 0)
        window.sendTouch(.ended, at: CGPoint(x: 102, y: 100), timestamp: 0.1)
        XCTAssertEqual(states(), [])                  // failed fires no action
        XCTAssertEqual(pan.state, .possible)          // reset after sequence
    }

    func testPanCancelsControlTracking() {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 400, height: 300))
        let control = UIControl(frame: CGRect(x: 0, y: 0, width: 300, height: 300))
        window.addSubview(control)
        let pan = UIPanGestureRecognizer()
        control.addGestureRecognizer(pan)
        var cancelFired = false
        var upFired = false
        control.addTarget(for: .touchCancel) { _, _ in cancelFired = true }
        control.addTarget(for: .touchUpInside) { _, _ in upFired = true }

        window.sendTouch(.began, at: CGPoint(x: 100, y: 100), timestamp: 0)
        XCTAssertTrue(control.isTracking)
        window.sendTouch(.moved, at: CGPoint(x: 130, y: 100), timestamp: 0.05)
        XCTAssertEqual(pan.state, .began)
        XCTAssertTrue(cancelFired)                    // cancelsTouchesInView
        XCTAssertFalse(control.isTracking)
        window.sendTouch(.ended, at: CGPoint(x: 130, y: 100), timestamp: 0.1)
        XCTAssertFalse(upFired)                       // never delivered
    }

    func testCancelsTouchesInViewFalseKeepsDelivery() {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 400, height: 300))
        let rec = TouchRecorder(frame: CGRect(x: 0, y: 0, width: 300, height: 300))
        window.addSubview(rec)
        let pan = UIPanGestureRecognizer()
        pan.cancelsTouchesInView = false
        rec.addGestureRecognizer(pan)

        window.sendTouch(.began, at: CGPoint(x: 100, y: 100), timestamp: 0)
        window.sendTouch(.moved, at: CGPoint(x: 130, y: 100), timestamp: 0.05)
        window.sendTouch(.ended, at: CGPoint(x: 130, y: 100), timestamp: 0.1)
        XCTAssertEqual(rec.log, ["began:1", "moved:1", "ended:1"])
    }
}

final class LongPressGestureTests: XCTestCase {
    func testLongPressFiresAfterMinimumDuration() {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 400, height: 300))
        let v = UIView(frame: CGRect(x: 0, y: 0, width: 200, height: 200))
        window.addSubview(v)
        var states: [UIGestureRecognizer.State] = []
        let press = UILongPressGestureRecognizer { states.append($0.state) }
        v.addGestureRecognizer(press)

        window.sendTouch(.began, at: CGPoint(x: 50, y: 50), timestamp: 0)
        window.tick(timestamp: 0.3)
        XCTAssertEqual(press.state, .possible)
        window.tick(timestamp: 0.51)
        XCTAssertEqual(press.state, .began)
        window.sendTouch(.moved, at: CGPoint(x: 60, y: 50), timestamp: 0.6)
        XCTAssertEqual(press.state, .changed)
        window.sendTouch(.ended, at: CGPoint(x: 60, y: 50), timestamp: 0.7)
        XCTAssertEqual(states, [.began, .changed, .ended])
        XCTAssertEqual(press.state, .possible)
    }

    func testLongPressFailsOnEarlyLiftOrMovement() {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 400, height: 300))
        let v = UIView(frame: CGRect(x: 0, y: 0, width: 200, height: 200))
        window.addSubview(v)
        var fired = false
        let press = UILongPressGestureRecognizer { _ in fired = true }
        v.addGestureRecognizer(press)

        // Early lift.
        window.sendTouch(.began, at: CGPoint(x: 50, y: 50), timestamp: 0)
        window.sendTouch(.ended, at: CGPoint(x: 50, y: 50), timestamp: 0.2)
        XCTAssertFalse(fired)
        XCTAssertEqual(press.state, .possible)
        // Excessive movement before the duration elapses.
        window.sendTouch(.began, at: CGPoint(x: 50, y: 50), timestamp: 1.0)
        window.sendTouch(.moved, at: CGPoint(x: 80, y: 50), timestamp: 1.2)
        XCTAssertEqual(press.state, .failed)
        window.tick(timestamp: 2.0)
        XCTAssertEqual(press.state, .failed)          // does not fire late
        window.sendTouch(.ended, at: CGPoint(x: 80, y: 50), timestamp: 2.1)
        XCTAssertFalse(fired)
    }

    func testLongPressFiresViaDelayedEventWithoutTick() {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 400, height: 300))
        let v = UIView(frame: CGRect(x: 0, y: 0, width: 200, height: 200))
        window.addSubview(v)
        var states: [UIGestureRecognizer.State] = []
        let press = UILongPressGestureRecognizer { states.append($0.state) }
        v.addGestureRecognizer(press)

        window.sendTouch(.began, at: CGPoint(x: 50, y: 50), timestamp: 0)
        // The lift itself is late: recognition then immediate end.
        window.sendTouch(.ended, at: CGPoint(x: 50, y: 50), timestamp: 0.8)
        XCTAssertEqual(states, [.began, .ended])
    }

    func testDisablingMidGestureCancels() {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 400, height: 300))
        let v = UIView(frame: CGRect(x: 0, y: 0, width: 200, height: 200))
        window.addSubview(v)
        var states: [UIGestureRecognizer.State] = []
        let press = UILongPressGestureRecognizer { states.append($0.state) }
        v.addGestureRecognizer(press)
        window.sendTouch(.began, at: CGPoint(x: 50, y: 50), timestamp: 0)
        window.tick(timestamp: 0.6)
        XCTAssertEqual(press.state, .began)
        press.isEnabled = false
        XCTAssertEqual(states, [.began, .cancelled])
    }
}

final class SwitchToggleModelTests: XCTestCase {
    /// The fitted thumb curve must interpolate the golden capture points.
    func testThumbCurveMatchesGoldenSamples() {
        let sw = UISwitch()
        let d = UISwitch.thumbDuration
        XCTAssertEqual(sw._thumbCurve(0.06 / d), 0.263, accuracy: 0.005)
        XCTAssertEqual(sw._thumbCurve(0.12 / d), 0.608, accuracy: 0.005)
        XCTAssertEqual(sw._thumbCurve(0.20 / d), 0.909, accuracy: 0.005)
        XCTAssertEqual(sw._thumbCurve(1.5), 1.0)
        XCTAssertEqual(sw._thumbCurve(0), 0.0)
    }

    func testCriticalSpringProgress() {
        let sw = UISwitch()
        // 1 - (1+x)e^-x at x = 9.24*0.12 = 1.1088
        XCTAssertEqual(sw._criticalSpringProgress(omega: 9.24, t: 0.12),
                       0.3041, accuracy: 0.001)
        XCTAssertEqual(sw._criticalSpringProgress(omega: 9.24, t: 0), 0)
        XCTAssertEqual(sw._criticalSpringProgress(omega: 15.708, t: 10), 1.0,
                       accuracy: 1e-9)
    }

    func testSetOnAnimatedRecordsToggle() {
        let sw = UISwitch()
        OpenUIKitRuntime.animationTime = 0
        sw.setOn(true, animated: true)
        XCTAssertTrue(sw.isOn)
        XCTAssertEqual(sw.toggleAnim?.fromOn, false)
        sw.setOn(true, animated: true)     // no-op: keeps the running anim
        XCTAssertEqual(sw.toggleAnim?.fromOn, false)
        sw.setOn(false, animated: false)   // unanimated: clears
        XCTAssertNil(sw.toggleAnim)
    }
}

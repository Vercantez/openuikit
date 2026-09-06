// Pinch / rotation / hover / screen-edge: MEASURED GestureProbe,
// iPhone SE 2x / iOS 26.1. Synthetic timestamps, no wall clock.
import XCTest
import Foundation
@testable import OpenUIKit

#if !os(Linux)
@MainActor
#endif
final class PinchGestureTests: XCTestCase {
    func makePinch() -> (UIWindow, UIView, UIPinchGestureRecognizer, () -> [UIGestureRecognizer.State]) {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 400, height: 400))
        let v = UIView(frame: window.bounds)
        window.addSubview(v)
        var states: [UIGestureRecognizer.State] = []
        let pinch = UIPinchGestureRecognizer { states.append($0.state) }
        v.addGestureRecognizer(pinch)
        return (window, v, pinch, { states })
    }

    func testPinchOutScaleAndCentroid() {
        let (window, v, pinch, states) = makePinch()
        // MEASURED: initial 100 pt, first move 110 pt → began, scale 110/108.
        window.sendTouch(.began, at: CGPoint(x: 100, y: 200), timestamp: 0, touchID: 0)
        window.sendTouch(.began, at: CGPoint(x: 200, y: 200), timestamp: 0, touchID: 1)
        XCTAssertEqual(pinch.state, .possible)
        XCTAssertEqual(pinch.scale, 1, accuracy: 1e-9)
        window.sendTouch(.moved, at: CGPoint(x: 95, y: 200), timestamp: 0.05, touchID: 0)
        window.sendTouch(.moved, at: CGPoint(x: 205, y: 200), timestamp: 0.05, touchID: 1)
        XCTAssertEqual(pinch.state, .began)
        XCTAssertEqual(pinch.scale, 110 / 108, accuracy: 1e-9)
        XCTAssertEqual(pinch.velocity, (110 / 108 - 1) / 0.05, accuracy: 1e-6)
        let loc = pinch.location(in: v)
        XCTAssertEqual(loc.x, 150, accuracy: 1e-9)
        XCTAssertEqual(loc.y, 200, accuracy: 1e-9)
        window.sendTouch(.moved, at: CGPoint(x: 50, y: 200), timestamp: 0.10, touchID: 0)
        window.sendTouch(.moved, at: CGPoint(x: 250, y: 200), timestamp: 0.10, touchID: 1)
        XCTAssertEqual(pinch.state, .changed)
        XCTAssertEqual(pinch.scale, 200 / 108, accuracy: 1e-9)
        pinch.scale = 1
        XCTAssertEqual(pinch.scale, 1, accuracy: 1e-9)
        window.sendTouch(.moved, at: CGPoint(x: 25, y: 200), timestamp: 0.15, touchID: 0)
        window.sendTouch(.moved, at: CGPoint(x: 275, y: 200), timestamp: 0.15, touchID: 1)
        XCTAssertEqual(pinch.scale, 250 / 200, accuracy: 1e-9)
        window.sendTouch(.ended, at: CGPoint(x: 25, y: 200), timestamp: 0.20, touchID: 0)
        window.sendTouch(.ended, at: CGPoint(x: 275, y: 200), timestamp: 0.20, touchID: 1)
        XCTAssertEqual(states().first, .began)
        XCTAssertEqual(states().last, .ended)
        XCTAssertTrue(states().contains(.changed))
        XCTAssertEqual(pinch.state, .possible)
    }

    func testPinchInUsesMinusEightHysteresis() {
        let (window, _, pinch, _) = makePinch()
        window.sendTouch(.began, at: CGPoint(x: 50, y: 300), timestamp: 0, touchID: 0)
        window.sendTouch(.began, at: CGPoint(x: 250, y: 300), timestamp: 0, touchID: 1)
        window.sendTouch(.moved, at: CGPoint(x: 55, y: 300), timestamp: 0.05, touchID: 0)
        window.sendTouch(.moved, at: CGPoint(x: 245, y: 300), timestamp: 0.05, touchID: 1)
        XCTAssertEqual(pinch.state, .began)
        XCTAssertEqual(pinch.scale, 190 / 192, accuracy: 1e-9)
    }

    func testPinchStaysPossibleBelowTenPoints() {
        let (window, _, pinch, states) = makePinch()
        window.sendTouch(.began, at: CGPoint(x: 140, y: 300), timestamp: 0, touchID: 0)
        window.sendTouch(.began, at: CGPoint(x: 240, y: 300), timestamp: 0, touchID: 1)
        window.sendTouch(.moved, at: CGPoint(x: 136, y: 300), timestamp: 0.05, touchID: 0)
        window.sendTouch(.moved, at: CGPoint(x: 244, y: 300), timestamp: 0.05, touchID: 1)
        XCTAssertEqual(pinch.state, .possible)
        XCTAssertEqual(states(), [])
        window.sendTouch(.ended, at: CGPoint(x: 136, y: 300), timestamp: 0.1, touchID: 0)
        window.sendTouch(.ended, at: CGPoint(x: 244, y: 300), timestamp: 0.1, touchID: 1)
        XCTAssertEqual(pinch.state, .possible)
    }

    func testOneFingerNeverRecognizes() {
        let (window, _, pinch, states) = makePinch()
        window.sendTouch(.began, at: CGPoint(x: 100, y: 200), timestamp: 0, touchID: 0)
        window.sendTouch(.moved, at: CGPoint(x: 160, y: 200), timestamp: 0.05, touchID: 0)
        window.sendTouch(.ended, at: CGPoint(x: 160, y: 200), timestamp: 0.1, touchID: 0)
        XCTAssertEqual(states(), [])
        XCTAssertEqual(pinch.state, .possible)
    }

    func testOneFingerRemainingStaysChangedThenEnds() {
        let (window, _, pinch, states) = makePinch()
        window.sendTouch(.began, at: CGPoint(x: 80, y: 200), timestamp: 0, touchID: 0)
        window.sendTouch(.began, at: CGPoint(x: 180, y: 200), timestamp: 0, touchID: 1)
        // Sequential sendTouch is one finger per event: first move 80→70
        // is 110 pt (began); keep the second move on the 10 pt recognition
        // step so the assertion sees `.began` rather than the follow-up
        // `.changed`. MEASURED 100→110 pt pinch-out.
        window.sendTouch(.moved, at: CGPoint(x: 75, y: 200), timestamp: 0.05, touchID: 0)
        window.sendTouch(.moved, at: CGPoint(x: 190, y: 200), timestamp: 0.05, touchID: 1)
        XCTAssertEqual(pinch.state, .began)
        window.sendTouch(.ended, at: CGPoint(x: 70, y: 200), timestamp: 0.1, touchID: 0)
        XCTAssertEqual(pinch.state, .changed)
        window.sendTouch(.ended, at: CGPoint(x: 200, y: 200), timestamp: 0.15, touchID: 1)
        XCTAssertEqual(states().last, .ended)
        XCTAssertEqual(pinch.state, .possible)
    }
}

#if !os(Linux)
@MainActor
#endif
final class RotationGestureTests: XCTestCase {
    func testRotationHysteresisAndSetRotation() {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 400, height: 400))
        let v = UIView(frame: window.bounds)
        window.addSubview(v)
        var states: [UIGestureRecognizer.State] = []
        let rot = UIRotationGestureRecognizer { states.append($0.state) }
        v.addGestureRecognizer(rot)

        window.sendTouch(.began, at: CGPoint(x: 150, y: 200), timestamp: 0, touchID: 0)
        window.sendTouch(.began, at: CGPoint(x: 250, y: 200), timestamp: 0, touchID: 1)
        XCTAssertEqual(rot.state, .possible)

        func pair(_ deg: CGFloat) -> (CGPoint, CGPoint) {
            let rad = deg * CGFloat.pi / 180
            let c = CGPoint(x: 200, y: 200)
            func p(_ src: CGPoint) -> CGPoint {
                let dx = src.x - c.x, dy = src.y - c.y
                return CGPoint(x: c.x + dx * cos(rad) - dy * sin(rad),
                               y: c.y + dx * sin(rad) + dy * cos(rad))
            }
            return (p(CGPoint(x: 150, y: 200)), p(CGPoint(x: 250, y: 200)))
        }
        let (a10, b10) = pair(10)
        window.sendTouch(.moved, at: a10, timestamp: 0.05, touchID: 0)
        window.sendTouch(.moved, at: b10, timestamp: 0.05, touchID: 1)
        XCTAssertEqual(rot.state, .began)
        XCTAssertEqual(rot.rotation, 5 * CGFloat.pi / 180, accuracy: 1e-6)
        XCTAssertEqual(rot.velocity, (10 * CGFloat.pi / 180) / 0.05, accuracy: 1e-5)

        let (a90, b90) = pair(90)
        window.sendTouch(.moved, at: a90, timestamp: 0.10, touchID: 0)
        window.sendTouch(.moved, at: b90, timestamp: 0.10, touchID: 1)
        XCTAssertEqual(rot.rotation, 85 * CGFloat.pi / 180, accuracy: 1e-6)
        rot.rotation = 0
        XCTAssertEqual(rot.rotation, 0, accuracy: 1e-9)
        let (a135, b135) = pair(135)
        window.sendTouch(.moved, at: a135, timestamp: 0.15, touchID: 0)
        window.sendTouch(.moved, at: b135, timestamp: 0.15, touchID: 1)
        XCTAssertEqual(rot.rotation, 45 * CGFloat.pi / 180, accuracy: 1e-6)
        window.sendTouch(.ended, at: a135, timestamp: 0.20, touchID: 0)
        window.sendTouch(.ended, at: b135, timestamp: 0.20, touchID: 1)
        XCTAssertEqual(states.last, .ended)
    }
}

#if !os(Linux)
@MainActor
#endif
final class HoverGestureTests: XCTestCase {
    func testHoverStateMachineViaSendHover() {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 400, height: 400))
        let v = UIView(frame: window.bounds)
        window.addSubview(v)
        var states: [UIGestureRecognizer.State] = []
        let hover = UIHoverGestureRecognizer { states.append($0.state) }
        v.addGestureRecognizer(hover)
        XCTAssertEqual(hover.zOffset, 0)
        XCTAssertEqual(hover.altitudeAngle, 0)
        window.sendHover(.entered, at: CGPoint(x: 40, y: 60), timestamp: 1)
        XCTAssertEqual(hover.state, .began)
        XCTAssertEqual(hover.location(in: v), CGPoint(x: 40, y: 60))
        window.sendHover(.moved, at: CGPoint(x: 80, y: 60), timestamp: 1.05)
        XCTAssertEqual(hover.state, .changed)
        window.sendHover(.exited, at: CGPoint(x: 80, y: 60), timestamp: 1.1)
        XCTAssertEqual(states, [.began, .changed, .ended])
        XCTAssertEqual(hover.state, .possible)
    }
}

#if !os(Linux)
@MainActor
#endif
final class ScreenEdgePanTests: XCTestCase {
    func testTopEdgeRecognizesDownwardDrag() {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 400, height: 400))
        let v = UIView(frame: window.bounds)
        window.addSubview(v)
        var states: [UIGestureRecognizer.State] = []
        let edge = UIScreenEdgePanGestureRecognizer { states.append($0.state) }
        edge.edges = .top
        v.addGestureRecognizer(edge)
        window.sendTouch(.began, at: CGPoint(x: 200, y: 10), timestamp: 0)
        window.sendTouch(.moved, at: CGPoint(x: 200, y: 40), timestamp: 0.05)
        XCTAssertEqual(edge.state, .began)
        window.sendTouch(.ended, at: CGPoint(x: 200, y: 40), timestamp: 0.1)
        XCTAssertEqual(states.last, .ended)
    }

    func testInteriorTouchFails() {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 400, height: 400))
        let v = UIView(frame: window.bounds)
        window.addSubview(v)
        let edge = UIScreenEdgePanGestureRecognizer()
        edge.edges = .left
        v.addGestureRecognizer(edge)
        window.sendTouch(.began, at: CGPoint(x: 80, y: 100), timestamp: 0)
        XCTAssertEqual(edge.state, .failed)
        window.sendTouch(.ended, at: CGPoint(x: 80, y: 100), timestamp: 0.05)
        XCTAssertEqual(edge.state, .possible)
    }
}
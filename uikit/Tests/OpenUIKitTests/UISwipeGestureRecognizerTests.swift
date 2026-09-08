import XCTest
import Foundation
@testable import OpenUIKit

#if !os(Linux)
@MainActor
#endif
final class UISwipeGestureRecognizerTests: XCTestCase {
    private typealias Direction = UISwipeGestureRecognizer.Direction

    func testTargetActionInitializerIsInherited() {
        let swipe = UISwipeGestureRecognizer(target: nil, action: nil)
        XCTAssertEqual(swipe.direction, .right)
        XCTAssertEqual(swipe.numberOfTouchesRequired, 1)
    }

    func testDefaultsMatchIOS26_1() {
        let swipe = UISwipeGestureRecognizer()
        XCTAssertEqual(swipe.direction, .right)
        XCTAssertEqual(swipe.numberOfTouchesRequired, 1)
        XCTAssertEqual(swipe.state, .possible)
        XCTAssertTrue(swipe.isEnabled)
        XCTAssertTrue(swipe.cancelsTouchesInView)
        XCTAssertFalse(swipe.delaysTouchesBegan)
        XCTAssertTrue(swipe.delaysTouchesEnded)
        XCTAssertEqual(swipe.numberOfTouches, 0)
        XCTAssertEqual(swipe.location(in: nil), .zero)
    }

    func testDirectionRawValuesAndUnmodifiedReadback() {
        XCTAssertEqual(Direction.right.rawValue, 1)
        XCTAssertEqual(Direction.left.rawValue, 2)
        XCTAssertEqual(Direction.up.rawValue, 4)
        XCTAssertEqual(Direction.down.rawValue, 8)
        let swipe = UISwipeGestureRecognizer()
        for raw: UInt in [0, 1, 2, 3, 4, 8, 15, 16, UInt.max] {
            swipe.direction = Direction(rawValue: raw)
            XCTAssertEqual(swipe.direction.rawValue, raw)
        }
        XCTAssertEqual(Direction([.right, .left]).rawValue, 3)
    }

    func testRequiredTouchesReadbackIsNotClamped() {
        let swipe = UISwipeGestureRecognizer()
        for count in [0, 1, 2, 3, 5, 6, 16, -1] {
            swipe.numberOfTouchesRequired = count
            XCTAssertEqual(swipe.numberOfTouchesRequired, count)
        }
    }

    private func recognize(direction: Direction = .right, required: Int = 1,
                           displacements: [CGPoint], elapsed: Double,
                           initialMove: CGPoint? = nil) -> Int {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 375, height: 667))
        let host = UIView(frame: window.bounds)
        window.addSubview(host)
        var actions = 0
        let swipe = UISwipeGestureRecognizer { sender in
            XCTAssertEqual(sender.state, .ended)
            actions += 1
        }
        swipe.direction = direction
        swipe.numberOfTouchesRequired = required
        host.addGestureRecognizer(swipe)
        let starts = displacements.indices.map { CGPoint(x: 120, y: 220 + CGFloat($0) * 80) }
        for (index, point) in starts.enumerated() {
            window.sendTouch(.began, at: point, timestamp: 1, touchID: index)
        }
        if let initialMove {
            window.sendTouch(.moved, at: CGPoint(x: 120 + initialMove.x, y: 220 + initialMove.y),
                             timestamp: 1.01, touchID: 0)
        }
        for (index, displacement) in displacements.enumerated() {
            let point = CGPoint(x: starts[index].x + displacement.x,
                                y: starts[index].y + displacement.y)
            window.sendTouch(.moved, at: point, timestamp: 1 + elapsed, touchID: index)
        }
        // A discrete action must not fire again for later movement or lift.
        for (index, displacement) in displacements.enumerated() {
            let point = CGPoint(x: starts[index].x + displacement.x,
                                y: starts[index].y + displacement.y)
            window.sendTouch(.moved, at: point, timestamp: 1 + elapsed, touchID: index)
            window.sendTouch(.ended, at: point, timestamp: 1.01 + elapsed, touchID: index)
        }
        XCTAssertEqual(swipe.state, .possible)
        return actions
    }

    func testAllCardinalDirectionsAndWrongDirection() {
        for (direction, vector): (Direction, CGPoint) in [
            (.right, CGPoint(x: 100, y: 0)), (.left, CGPoint(x: -100, y: 0)),
            (.up, CGPoint(x: 0, y: -100)), (.down, CGPoint(x: 0, y: 100)),
        ] {
            XCTAssertEqual(recognize(direction: direction, displacements: [vector], elapsed: 0.1), 1)
            XCTAssertEqual(recognize(direction: direction,
                                     displacements: [CGPoint(x: -vector.x, y: -vector.y)], elapsed: 0.1), 0)
        }
    }

    func testMeasuredTimeDependentMovementBoundaries() {
        // Independent SwipeProbe samples, each bracketing a threshold by
        // ±.001 pt on the iOS 26.1 SE. These are captured distances, not a
        // second implementation of the threshold calculation.
        let samples: [(Double, CGFloat, CGFloat)] = [
            (0, 50, 50), (0.1, 45.3, 45.1), (0.2, 40.6, 40.2),
            (0.3, 35.9, 35.3), (0.4, 31.2, 30.4), (0.5, 26.5, 25.5),
        ]
        for (elapsed, primary, secondary) in samples {
            XCTAssertEqual(recognize(displacements: [CGPoint(x: primary - 0.001, y: 0)],
                                     elapsed: elapsed), 0, "primary below at \(elapsed)")
            XCTAssertEqual(recognize(displacements: [CGPoint(x: primary + 0.001, y: 0)],
                                     elapsed: elapsed), 1, "primary above at \(elapsed)")
            XCTAssertEqual(recognize(displacements: [CGPoint(x: 100, y: secondary - 0.001)],
                                     elapsed: elapsed), 1, "secondary below at \(elapsed)")
            XCTAssertEqual(recognize(displacements: [CGPoint(x: 100, y: secondary + 0.001)],
                                     elapsed: elapsed), 0, "secondary above at \(elapsed)")
        }
    }

    func testMaximumDurationIsHalfASecondInclusive() {
        XCTAssertEqual(recognize(displacements: [CGPoint(x: 100, y: 0)], elapsed: 0.5), 1)
        XCTAssertEqual(recognize(displacements: [CGPoint(x: 100, y: 0)], elapsed: 0.501), 0)
    }

    func testEveryRequiredTouchMustMoveInTheConfiguredDirection() {
        let right = CGPoint(x: 100, y: 0)
        XCTAssertEqual(recognize(required: 2, displacements: [right, right], elapsed: 0.1), 1)
        XCTAssertEqual(recognize(required: 1, displacements: [right, right], elapsed: 0.1), 0)
        XCTAssertEqual(recognize(required: 2, displacements: [right], elapsed: 0.1), 0)
        XCTAssertEqual(recognize(required: 2, displacements: [right, .zero], elapsed: 0.1), 0)
        XCTAssertEqual(recognize(required: 2, displacements: [right, CGPoint(x: 50, y: 0)], elapsed: 0.1), 1)
        XCTAssertEqual(recognize(required: 2, displacements: [right, CGPoint(x: -100, y: 0)], elapsed: 0.1), 0)
        XCTAssertEqual(recognize(required: 0, displacements: [right], elapsed: 0.1), 0)
    }

    func testMasksAndOppositeMovementMatchCapturedSequences() {
        let right = CGPoint(x: 100, y: 0)
        XCTAssertEqual(recognize(direction: [.right, .left], displacements: [right], elapsed: 0.1), 1)
        XCTAssertEqual(recognize(direction: [.right, .left], displacements: [CGPoint(x: -100, y: 0)], elapsed: 0.1), 1)
        XCTAssertEqual(recognize(direction: [], displacements: [right], elapsed: 0.1), 0)
        XCTAssertEqual(recognize(direction: Direction(rawValue: 16), displacements: [right], elapsed: 0.1), 0)
        XCTAssertEqual(recognize(direction: [.right, .down], displacements: [right], elapsed: 0.1), 1)
        XCTAssertEqual(recognize(direction: [.right, .down], displacements: [CGPoint(x: 0, y: 100)], elapsed: 0.1), 0)
        XCTAssertEqual(recognize(direction: [.right, .left, .up, .down],
                                 displacements: [CGPoint(x: 50, y: 50)], elapsed: 0), 1)
        XCTAssertEqual(recognize(displacements: [right], elapsed: 0.1, initialMove: CGPoint(x: -0.1, y: 0)), 0)
        XCTAssertEqual(recognize(displacements: [right], elapsed: 0.1, initialMove: CGPoint(x: 0, y: 20)), 1)
    }

    func testResetAllowsAnotherIndependentSwipe() {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 375, height: 667))
        var actions = 0
        let swipe = UISwipeGestureRecognizer { _ in actions += 1 }
        window.addGestureRecognizer(swipe)
        for time in [1.0, 3.0] {
            window.sendTouch(.began, at: CGPoint(x: 100, y: 200), timestamp: time)
            window.sendTouch(.moved, at: CGPoint(x: 200, y: 200), timestamp: time + 0.1)
            window.sendTouch(.ended, at: CGPoint(x: 200, y: 200), timestamp: time + 0.2)
        }
        XCTAssertEqual(actions, 2)
        XCTAssertEqual(swipe.numberOfTouches, 0)
    }
}

#if canImport(Foundation)
import Foundation
#endif

/// A discrete swipe recognizer. Its thresholds are measured from the real
/// iOS 26.1 SE 2x oracle in Tools/oracle2/swipeprobe/ios-26.1.txt; recognition
/// uses the same event timestamps as the other portable recognizers.
@preconcurrency @MainActor
open class UISwipeGestureRecognizer: UIGestureRecognizer {
    public struct Direction: OptionSet, Sendable, Hashable {
        public let rawValue: UInt
        public init(rawValue: UInt) { self.rawValue = rawValue }

        // SwipeProbe, iPhone SE / iOS 26.1: raw right/left/up/down = 1/2/4/8.
        public static let right = Direction(rawValue: 1)
        public static let left = Direction(rawValue: 2)
        public static let up = Direction(rawValue: 4)
        public static let down = Direction(rawValue: 8)
    }

    // SwipeProbe defaults: direction=1, required touches=1. Readback retains
    // all assigned bits and touch counts (including 0 and -1), without clamps.
    public var direction: Direction = .right
    public var numberOfTouchesRequired: Int = 1

    // SwipeProbe private-property readback: duration=.5, primary=50,
    // secondary=50, minimum decay=.06, maximum decay=.02. Independent touch
    // sweeps bracket primary/secondary limits to ±.001 pt at elapsed times
    // 0/.1/.2/.3/.4/.5 s: 50/50, 45.3/45.1, 40.6/40.2, 35.9/35.3,
    // 31.2/30.4, 26.5/25.5. Thus each limit is 50*(1-t*(1-decay)).
    private static let maximumDuration: TimeInterval = 0.5
    private static let initialMovement: CGFloat = 50
    private static let minimumMovementDecay: CGFloat = 0.06
    private static let maximumMovementDecay: CGFloat = 0.02

    private var startTimestamp: TimeInterval?
    private var startLocations: [Int: CGPoint] = [:]

    open override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        guard _state == .possible else { return }
        if startTimestamp == nil { startTimestamp = event.timestamp }
        for touch in touches {
            startLocations[touch.touchID] = touch.location(in: view)
        }
    }

    open override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
        guard _state == .possible, let startTimestamp else { return }
        let elapsed = event.timestamp - startTimestamp
        // SwipeProbe duration samples: .500 s recognizes, .501 s fails.
        guard elapsed <= Self.maximumDuration else {
            state = .failed
            return
        }
        let minimum = Self.initialMovement *
            (1 - CGFloat(elapsed) * (1 - Self.minimumMovementDecay))
        let maximumSecondary = Self.initialMovement *
            (1 - CGFloat(elapsed) * (1 - Self.maximumMovementDecay))
        let horizontal = !direction.intersection([.left, .right]).isEmpty
        let vertical = !direction.intersection([.up, .down]).isEmpty
        guard horizontal || vertical else { return }
        var recognized = numberOfTouchesRequired > 0 &&
            trackedTouches.count == numberOfTouchesRequired

        // SwipeProbe two-finger samples: 100/0 pt fails; 100/50 pt recognizes;
        // 100/-100 pt fails. Every finger must qualify, not just the centroid.
        for touch in trackedTouches {
            guard let start = startLocations[touch.touchID] else { return }
            let point = touch.location(in: view)
            let dx = point.x - start.x
            let dy = point.y - start.y
            // Measured opposite allowance is 0 pt: -0.1 then +100 fails a
            // right swipe. Retreating +20→+10→+100 still recognizes.
            if (direction.contains(.right) && !direction.contains(.left) && dx < 0) ||
               (direction.contains(.left) && !direction.contains(.right) && dx > 0) ||
               (direction.contains(.up) && !direction.contains(.down) && dy > 0) ||
               (direction.contains(.down) && !direction.contains(.up) && dy < 0) {
                state = .failed
                return
            }
            // SwipeProbe mixed-axis masks: [.right,.down] and all four bits
            // recognize (100,0), but [.right,.down] rejects (0,100)/(100,100).
            // Horizontal bits select the primary axis when both are present.
            let primary = horizontal ? abs(dx) : abs(dy)
            let secondary = horizontal ? abs(dy) : abs(dx)
            if secondary > maximumSecondary {
                state = .failed
                return
            }
            if primary < minimum { recognized = false }
        }
        if recognized { state = .ended }
    }

    open override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
        // SwipeProbe actions occur during movement; lifting an unrecognized
        // sequence (including an unmoved touch) produces no action.
        if _state == .possible { state = .failed }
    }

    open override func reset() {
        super.reset()
        startTimestamp = nil
        startLocations.removeAll()
    }
}

// UITouch. Owner: event module (M7).
//
// A touch is an identity object that lives for the whole finger-down →
// finger-up sequence; the window mutates it in place as the host reports
// phases (UIKit semantics). All timestamps come in through the API —
// nothing in the portable core reads a wall clock, so synthetic touch
// sequences are fully deterministic.

public typealias TimeInterval = Double

public final class UITouch: Hashable {
    public enum Phase: Sendable {
        case began, moved, stationary, ended, cancelled
    }

    public internal(set) var phase: Phase = .began
    /// Event time in seconds. Host-provided (no wall clock in the core).
    public internal(set) var timestamp: TimeInterval = 0
    /// Consecutive-tap count (UIKit: taps in quick succession near the same
    /// spot increment it; see UIWindow.multiTapInterval/Slop).
    public internal(set) var tapCount: Int = 1

    /// The view returned by hit-testing at touch begin (touch delivery
    /// target). Stays fixed for the touch's lifetime, like UIKit.
    public internal(set) weak var view: UIView?
    public internal(set) weak var window: UIWindow?

    /// Gesture recognizers observing this touch (collected from the
    /// hit-test view's superview chain at touch begin).
    public internal(set) var gestureRecognizers: [UIGestureRecognizer]? = nil

    /// Set when a recognizer recognized and cancelled this touch's delivery
    /// to `view` (cancelsTouchesInView): the view got touchesCancelled and
    /// receives nothing further for this touch.
    var deliveryCancelled = false

    /// Locations in the window's coordinate space.
    var locationInWindow: CGPoint = .zero
    var previousLocationInWindow: CGPoint = .zero

    /// Stable identity supplied by the host (multi-touch); internal only.
    let touchID: Int

    init(touchID: Int) {
        self.touchID = touchID
    }

    public func location(in view: UIView?) -> CGPoint {
        guard let view else { return locationInWindow }
        return view.convert(locationInWindow, from: window)
    }

    public func previousLocation(in view: UIView?) -> CGPoint {
        guard let view else { return previousLocationInWindow }
        return view.convert(previousLocationInWindow, from: window)
    }

    // MARK: Hashable (identity)

    public static func == (lhs: UITouch, rhs: UITouch) -> Bool { lhs === rhs }
    public func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self))
    }
}

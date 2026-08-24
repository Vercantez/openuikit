// UIGestureRecognizer + tap / pan / long-press. Owner: event module (M7).
//
// The base class implements UIKit's state machine:
//
//   discrete (tap):        possible ──────────────► ended | failed
//   continuous (pan/press):possible ─► began ─► changed* ─► ended | cancelled
//                          possible ─► failed
//
// Actions fire on .began/.changed/.ended/.cancelled (not .possible/.failed),
// matching UIKit. Recognition (entering .began, or .ended straight from
// .possible) sets pendingCancelTouches; UIWindow then applies the standard
// cancelsTouchesInView behavior. After the touch sequence completes the
// window calls _sequenceEnded(), which invokes reset() and returns the
// recognizer to .possible.
//
// No ObjC runtime: targets are closures (`addTarget { r in ... }`).
// All timing is event-timestamp based — no wall clock (deterministic).

open class UIGestureRecognizer {
    public enum State: Sendable {
        case possible, began, changed, ended, cancelled, failed
    }

    public typealias ActionHandler = (UIGestureRecognizer) -> Void

    /// Current state. Subclasses drive transitions by assigning (like
    /// UIGestureRecognizerSubclass); assigning fires the attached actions
    /// for .began/.changed/.ended/.cancelled.
    public var state: State {
        get { _state }
        set { transition(to: newValue) }
    }
    var _state: State = .possible

    public internal(set) weak var view: UIView?
    /// Disabling mid-gesture cancels it (UIKit).
    public var isEnabled: Bool = true {
        didSet {
            if !isEnabled, _state == .began || _state == .changed {
                transition(to: .cancelled)
            }
        }
    }
    /// Standard UIKit behavior: when this recognizer recognizes, the
    /// touches it tracks are cancelled in their hit-test view.
    public var cancelsTouchesInView = true
    public var name: String?

    /// Touches this recognizer is observing (insertion order).
    var trackedTouches: [UITouch] = []
    /// Set on recognition; consumed by UIWindow.processRecognitions.
    var pendingCancelTouches = false

    private var actions: [(token: Int, handler: ActionHandler)] = []
    private var nextToken = 0

    public init(handler: ActionHandler? = nil) {
        if let handler { addTarget(handler) }
    }

    // MARK: Targets

    @discardableResult
    public func addTarget(_ handler: @escaping ActionHandler) -> Int {
        nextToken += 1
        actions.append((nextToken, handler))
        return nextToken
    }

    public func removeTarget(_ token: Int) {
        actions.removeAll { $0.token == token }
    }

    // MARK: State machine

    func transition(to newState: State) {
        let old = _state
        _state = newState
        switch newState {
        case .began, .changed, .ended, .cancelled:
            // Recognition happens on .began (continuous) or on .ended
            // straight out of .possible (discrete).
            if newState == .began || (newState == .ended && old == .possible) {
                pendingCancelTouches = true
            }
            for a in actions { a.handler(self) }
        case .possible, .failed:
            break
        }
    }

    /// Called by the window when every tracked touch has ended/cancelled.
    func _sequenceEnded() {
        reset()
    }

    /// Return to .possible and clear per-gesture state. Subclasses override
    /// (and call super) to clear their own accumulators.
    open func reset() {
        _state = .possible
        pendingCancelTouches = false
        trackedTouches.removeAll()
    }

    // MARK: Locations

    /// Centroid of the tracked touches, in `view`'s coordinates (nil =
    /// window coordinates), like UIKit.
    open func location(in view: UIView?) -> CGPoint {
        let live = trackedTouches.filter { $0.phase != .cancelled }
        guard !live.isEmpty else { return .zero }
        var x: CGFloat = 0, y: CGFloat = 0
        for t in live {
            let p = t.location(in: view)
            x += p.x
            y += p.y
        }
        return CGPoint(x: x / CGFloat(live.count), y: y / CGFloat(live.count))
    }

    public var numberOfTouches: Int { trackedTouches.count }

    // MARK: Touch observation (window-called wrappers)

    func _touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        for t in touches.sorted(by: { $0.touchID < $1.touchID })
        where !trackedTouches.contains(where: { $0 === t }) {
            trackedTouches.append(t)
        }
        touchesBegan(touches, with: event)
    }
    func _touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
        touchesMoved(touches, with: event)
    }
    func _touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
        touchesEnded(touches, with: event)
    }
    func _touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent) {
        touchesCancelled(touches, with: event)
    }

    /// Subclass observation points (UIGestureRecognizerSubclass).
    open func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {}
    open func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {}
    open func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {}
    open func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent) {
        if _state == .began || _state == .changed {
            transition(to: .cancelled)
        } else if _state == .possible {
            transition(to: .failed)
        }
    }

    /// Time-only advance (no touch change): UIWindow.tick / stationary
    /// phases call this so time-based recognizers (long press) can fire.
    open func timeAdvanced(to timestamp: TimeInterval, with event: UIEvent) {}
}

// MARK: - Tap

public final class UITapGestureRecognizer: UIGestureRecognizer {
    public var numberOfTapsRequired: Int = 1
    public var numberOfTouchesRequired: Int = 1
    /// Movement beyond this many points fails the tap (UIKit's private
    /// allowable movement is ~10 pt on iPhone-class devices).
    public var allowableMovement: CGFloat = 10

    var initialLocation: CGPoint = .zero

    public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        guard _state == .possible else { return }
        if trackedTouches.count > numberOfTouchesRequired {
            state = .failed
            return
        }
        if let t = touches.first, trackedTouches.count == 1 {
            initialLocation = t.location(in: nil)
        }
    }

    public override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
        guard _state == .possible else { return }
        for t in touches {
            let p = t.location(in: nil)
            let dx = p.x - initialLocation.x, dy = p.y - initialLocation.y
            if (dx * dx + dy * dy).squareRoot() > allowableMovement {
                state = .failed
                return
            }
        }
    }

    public override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
        guard _state == .possible else { return }
        guard trackedTouches.count == numberOfTouchesRequired else {
            state = .failed
            return
        }
        // Multi-tap: the window maintains UITouch.tapCount across quick
        // successive touches; the N-th tap of a sequence recognizes.
        if let t = touches.first, t.tapCount >= numberOfTapsRequired {
            state = .ended
        }
        // Otherwise stay .possible; the sequence reset returns us to idle
        // and the next tap (with a higher tapCount) can recognize.
    }
}

// MARK: - Pan

public final class UIPanGestureRecognizer: UIGestureRecognizer {
    public var minimumNumberOfTouches: Int = 1
    public var maximumNumberOfTouches: Int = Int.max
    /// Activation slop: the touch must move this far (points, straight-line)
    /// from touchdown before the pan begins (UIKit ~10 pt).
    public var activationDistance: CGFloat = 10

    var startLocation: CGPoint = .zero          // window coords, at touchdown
    var translationOrigin: CGPoint = .zero      // window coords baseline
    var lastLocation: CGPoint = .zero
    var lastTimestamp: TimeInterval = 0
    var velocityInWindow: CGPoint = .zero

    public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        guard _state == .possible, trackedTouches.count == 1 else { return }
        startLocation = location(in: nil)
        translationOrigin = startLocation
        lastLocation = startLocation
        lastTimestamp = event.timestamp
        velocityInWindow = .zero
    }

    public override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
        let p = location(in: nil)
        let dt = event.timestamp - lastTimestamp
        if dt > 0 {
            velocityInWindow = CGPoint(x: (p.x - lastLocation.x) / CGFloat(dt),
                                       y: (p.y - lastLocation.y) / CGFloat(dt))
        }
        lastLocation = p
        lastTimestamp = event.timestamp

        switch _state {
        case .possible:
            let dx = p.x - startLocation.x, dy = p.y - startLocation.y
            if (dx * dx + dy * dy).squareRoot() > activationDistance {
                if trackedTouches.count >= minimumNumberOfTouches,
                   trackedTouches.count <= maximumNumberOfTouches {
                    state = .began
                } else {
                    state = .failed
                }
            }
        case .began, .changed:
            state = .changed
        default:
            break
        }
    }

    public override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
        switch _state {
        case .began, .changed:
            let live = trackedTouches.filter { $0.phase != .ended && $0.phase != .cancelled }
            if live.isEmpty { state = .ended }
        case .possible:
            state = .failed
        default:
            break
        }
    }

    /// Total translation since the pan's touchdown (adjusted by
    /// setTranslation), in `view`'s coordinates.
    public func translation(in view: UIView?) -> CGPoint {
        let cur = location(in: nil)
        let d = CGPoint(x: cur.x - translationOrigin.x, y: cur.y - translationOrigin.y)
        return convertVector(d, to: view)
    }

    public func setTranslation(_ translation: CGPoint, in view: UIView?) {
        let cur = location(in: nil)
        let dWindow = convertVectorFromView(translation, from: view)
        translationOrigin = CGPoint(x: cur.x - dWindow.x, y: cur.y - dWindow.y)
    }

    /// Points per second, in `view`'s coordinates.
    public func velocity(in view: UIView?) -> CGPoint {
        convertVector(velocityInWindow, to: view)
    }

    func convertVector(_ v: CGPoint, to view: UIView?) -> CGPoint {
        guard let view, let window = trackedTouches.first?.window else { return v }
        let o = view.convert(CGPoint.zero, from: window)
        let p = view.convert(v, from: window)
        return CGPoint(x: p.x - o.x, y: p.y - o.y)
    }

    func convertVectorFromView(_ v: CGPoint, from view: UIView?) -> CGPoint {
        guard let view, let window = trackedTouches.first?.window else { return v }
        let o = view.convert(CGPoint.zero, to: window)
        let p = view.convert(v, to: window)
        return CGPoint(x: p.x - o.x, y: p.y - o.y)
    }

    public override func reset() {
        super.reset()
        velocityInWindow = .zero
    }
}

// MARK: - Long press

public final class UILongPressGestureRecognizer: UIGestureRecognizer {
    public var minimumPressDuration: TimeInterval = 0.5
    /// UIKit default: 10 pt of movement allowed before recognition.
    public var allowableMovement: CGFloat = 10
    public var numberOfTapsRequired: Int = 0
    public var numberOfTouchesRequired: Int = 1

    var initialLocation: CGPoint = .zero
    var pressStart: TimeInterval = 0

    public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        guard _state == .possible else { return }
        if trackedTouches.count > numberOfTouchesRequired {
            state = .failed
            return
        }
        if trackedTouches.count == numberOfTouchesRequired {
            initialLocation = location(in: nil)
            pressStart = event.timestamp
        }
    }

    public override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
        maybeFire(at: event.timestamp)
        switch _state {
        case .possible:
            let p = location(in: nil)
            let dx = p.x - initialLocation.x, dy = p.y - initialLocation.y
            if (dx * dx + dy * dy).squareRoot() > allowableMovement {
                state = .failed
            }
        case .began, .changed:
            state = .changed
        default:
            break
        }
    }

    public override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
        maybeFire(at: event.timestamp)
        switch _state {
        case .began, .changed:
            state = .ended
        case .possible:
            state = .failed // lifted before minimumPressDuration
        default:
            break
        }
    }

    public override func timeAdvanced(to timestamp: TimeInterval, with event: UIEvent) {
        maybeFire(at: timestamp)
    }

    /// Recognize once the press has been held long enough (before any
    /// movement/lift disqualified it).
    func maybeFire(at timestamp: TimeInterval) {
        guard _state == .possible,
              trackedTouches.count == numberOfTouchesRequired,
              timestamp - pressStart >= minimumPressDuration else { return }
        state = .began
    }
}

// UIEvent + UIWindow touch routing. Owner: event module (M7).
//
// The portable core has no run loop and reads no wall clock: the HOST turns
// its native input stream (SDL, wasm, test harness) into calls on UIWindow:
//
//   window.sendTouch(.began, at: p, timestamp: t, touchID: 0)
//   window.sendTouch(.moved, at: p2, timestamp: t + 0.016, touchID: 0)
//   window.sendTouch(.ended, at: p2, timestamp: t + 0.1, touchID: 0)
//   window.tick(timestamp: now)   // time-only advance (long-press firing)
//
// Delivery per event (UIKit order):
//   1. Gesture recognizers on the hit-test view's superview chain observe
//      the touches first.
//   2. Recognition side effects: a recognizer entering .began (continuous)
//      or .ended-from-.possible (discrete) with cancelsTouchesInView sends
//      touchesCancelled to the views of its touches; those touches deliver
//      nothing further to their view.
//   3. The hit-test view receives touchesBegan/Moved/Ended/Cancelled.
//   4. Sequence cleanup: recognizers whose touches have all ended are reset
//      to .possible.

// M15: a DEFAULT ARGUMENT or an `@inlinable` body may only use members whose
// defining module THIS FILE imports -- `CGRect.zero` and `CGFloat.pi` do not
// ride in on OpenCoreGraphics' typealias the way ordinary uses do. These are
// SCOPED imports on purpose: they satisfy that rule without pulling in
// CoreGraphics' CGColor / CGAffineTransform, which would collide with
// OpenCoreGraphics' own. One knock-on, measured: in a file where the name is
// visible twice, `[CGFloat](repeating:count:)` array sugar stops parsing as a
// type; spell it `Array<CGFloat>(...)`.
#if canImport(CoreGraphics)
import struct CoreFoundation.CGFloat
import struct CoreGraphics.CGPoint
import struct CoreGraphics.CGRect
import struct CoreGraphics.CGSize
#elseif canImport(Foundation)
import Foundation
#endif

@preconcurrency @MainActor
public final class UIEvent {
    public enum EventType: Sendable {
        case touches
    }

    public let type: EventType = .touches
    public internal(set) var timestamp: TimeInterval

    var eventTouches: Set<UITouch> = []

    public var allTouches: Set<UITouch>? {
        eventTouches.isEmpty ? nil : eventTouches
    }

    public func touches(for view: UIView) -> Set<UITouch>? {
        let s = eventTouches.filter { $0.view === view }
        return s.isEmpty ? nil : s
    }

    public func touches(for gesture: UIGestureRecognizer) -> Set<UITouch>? {
        let s = eventTouches.filter {
            ($0.gestureRecognizers ?? []).contains { $0 === gesture }
        }
        return s.isEmpty ? nil : s
    }

    init(timestamp: TimeInterval) {
        self.timestamp = timestamp
    }
}

// MARK: - UIWindow

@preconcurrency @MainActor
open class UIWindow: UIView {
    /// Multi-tap sequence rules (UITouch.tapCount): a touch that begins
    /// within `multiTapInterval` seconds of the previous touch's end and
    /// within `multiTapSlop` points of its position continues the tap
    /// sequence. Host-tunable.
    public static var multiTapInterval: TimeInterval = 0.35
    public static var multiTapSlop: CGFloat = 30

    /// Current first responder (text-input focus). Set through
    /// UIResponder.becomeFirstResponder / resignFirstResponder; the host
    /// feeds keyboard input to it via sendText/sendKey (UITextInput.swift).
    /// UIKit stores the first responder on the window too — which is why a
    /// responder must be installed in one to take focus.
    /// Owner: text-input module (additive, coordinated with event module);
    /// widened from UIView? to UIResponder? by the lifecycle module (M12),
    /// since a view controller can hold focus as well.
    public internal(set) weak var firstResponder: UIResponder?

    // MARK: Window role (lifecycle module, M12)

    /// The scene this window belongs to, when the app opted into scenes.
    /// nil in the pre-scene shape OpenUIKit's hosts boot, which is what
    /// makes a window's next responder the application itself.
    public weak var windowScene: UIWindowScene? {
        didSet {
            if let s = windowScene { UIApplication.shared._connect(scene: s) }
        }
    }

    /// UIKit: window -> its window scene, if any -> UIApplication.
    open override var next: UIResponder? { windowScene ?? UIApplication.shared }

    override var _firstResponderWindow: UIWindow? { self }

    public var isKeyWindow: Bool { UIApplication.shared.keyWindow === self }

    /// The controller whose view fills the window. Setting it swaps the old
    /// root view out and installs the new one at the window's bounds — the
    /// standard `window.rootViewController = vc` app boot.
    public var rootViewController: UIViewController? {
        didSet {
            guard rootViewController !== oldValue else { return }
            oldValue?.viewIfLoaded?.removeFromSuperview()
            guard let vc = rootViewController else { return }
            vc.loadViewIfNeeded()
            let v = vc.view!
            v.frame = bounds
            addSubview(v)
            setNeedsLayout()
        }
    }

    public override init(frame: CGRect = .zero) {
        super.init(frame: frame)
        UIApplication.shared._register(window: self)
    }

    /// Make this the key window (UIKit also makes it visible; OpenUIKit has
    /// no window server, so visibility is the host's business).
    public func makeKey() { UIApplication.shared._makeKey(window: self) }

    public func makeKeyAndVisible() {
        isHidden = false
        makeKey()
    }

    /// Active touches by host-provided touch identifier.
    var activeTouches: [Int: UITouch] = [:]
    /// Previous tap-sequence terminus (for tapCount).
    var lastTapEnd: (timestamp: TimeInterval, location: CGPoint, tapCount: Int)?

    // MARK: Host-facing touch injection

    /// Feed one touch-phase change from the host's input stream. Returns the
    /// (persistent) UITouch, or nil for phase updates of unknown touchIDs.
    /// Timestamps are host-provided seconds — any monotonic clock; all
    /// gesture timing derives from them, never from a wall clock.
    @discardableResult
    public func sendTouch(_ phase: UITouch.Phase, at point: CGPoint,
                          timestamp: TimeInterval, touchID: Int = 0) -> UITouch? {
        let touch: UITouch
        switch phase {
        case .began:
            let t = UITouch(touchID: touchID)
            t.window = self
            t.locationInWindow = point
            t.previousLocationInWindow = point
            t.timestamp = timestamp
            t.phase = .began
            if let last = lastTapEnd,
               timestamp - last.timestamp <= UIWindow.multiTapInterval,
               (point.x - last.location.x).magnitude <= UIWindow.multiTapSlop,
               (point.y - last.location.y).magnitude <= UIWindow.multiTapSlop {
                t.tapCount = last.tapCount + 1
            } else {
                t.tapCount = 1
            }
            // Hit-test from the window; the view (and the recognizers on its
            // superview chain) stay fixed for the touch's lifetime. UIKit
            // lays out before event delivery — do the same so controls that
            // assert geometry in layoutSubviews (UISwitch's forced size)
            // hit-test correctly.
            layoutIfNeeded()
            t.view = hitTest(point, with: nil)
            var recs: [UIGestureRecognizer] = []
            var v: UIView? = t.view
            while let cur = v {
                // M13: a delegate can refuse the touch outright, and the
                // recognizer then never observes it (UIKit's
                // gestureRecognizer(_:shouldReceive:)).
                recs.append(contentsOf: cur._gestureRecognizers.filter {
                    $0.delegate?.gestureRecognizer($0, shouldReceive: t) ?? true
                })
                v = cur.superview
            }
            t.gestureRecognizers = recs.isEmpty ? nil : recs
            // UIScrollView content-touch semantics (M7.5): a touch-down
            // inside a scroll view stops any deceleration (finger catch —
            // the touch is consumed, content never sees it), and
            // delaysContentTouches holds touchesBegan delivery to content
            // subviews for ~150 ms (or until the scroll pan claims/fails).
            if let sv = UIScrollView.enclosingScrollView(of: t.view),
               sv.isScrollEnabled {
                let caught = sv.touchBeganInContent()
                if caught {
                    t.deliveryCancelled = true // scroll-catch tap: consumed
                } else if sv.delaysContentTouches, t.view !== sv {
                    t.beganPending = true
                    t.delayDeadline = timestamp + UIScrollView.contentTouchDelay
                    t.delayingScrollView = sv
                }
            }
            activeTouches[touchID] = t
            touch = t
        case .moved, .stationary, .ended, .cancelled:
            guard let t = activeTouches[touchID] else { return nil }
            t.previousLocationInWindow = t.locationInWindow
            t.locationInWindow = point
            t.timestamp = timestamp
            t.phase = phase
            touch = t
        }

        let event = UIEvent(timestamp: timestamp)
        event.eventTouches = [touch]
        sendEvent(event)

        if phase == .ended {
            lastTapEnd = (timestamp, point, touch.tapCount)
        }
        if phase == .ended || phase == .cancelled {
            UIScrollView.enclosingScrollView(of: touch.view)?.touchSequenceEnded()
            activeTouches[touchID] = nil
        }
        return touch
    }

    /// Advance event time without any touch change: gives time-based
    /// recognizers (long press) a chance to fire while a touch is held
    /// stationary. Call from the host's frame loop while touches are down.
    public func tick(timestamp: TimeInterval) {
        // Scroll deceleration/bounce advances on the SAME host clock as
        // everything else (openhost feeds OpenUIKitRuntime.animationTime
        // here) — scripted captures stay deterministic.
        UIScrollView._stepScrollAnimations(to: timestamp)
        // Navigation push/pop cleanup + viewDidAppear/DidDisappear fire when
        // the host clock passes the transition end (same pattern; see
        // UINavigationController).
        UINavigationController._stepTransitions(to: timestamp)
        // A released sheet drag settles (springs back or completes its
        // dismissal) on the same clock — same additive pattern.
        _UIPageSheetView._stepSheetInteractions(to: timestamp)
        // UIView.animate completion handlers fire when their animation ends
        // on this clock, after the steppers above (a completion may start the
        // next animation, and it should see a settled scroll/transition).
        UIView._stepAnimationCompletions(to: timestamp)
        // Caret blink of the focused text editor advances on the same host
        // clock (text-input module; additive like the steppers above).
        UITextInputState._stepCaretBlink(to: timestamp)
        // Scheduled `Timer`s fire off the same clock — there is no run loop,
        // so this tick IS the run-loop turn (Sources/OpenUIKit/Timer.swift).
        Timer._step(to: timestamp)
        flushDelayedContentTouches(at: timestamp)
        guard !activeTouches.isEmpty else { return }
        let event = UIEvent(timestamp: timestamp)
        event.eventTouches = Set(activeTouches.values)
        let recognizers = involvedRecognizers(event.eventTouches)
        for r in recognizers where r.isEnabled {
            r.timeAdvanced(to: timestamp, with: event)
        }
        processRecognitions(recognizers, event: event)
        finishSequences(event.eventTouches)
    }

    // MARK: Event dispatch

    /// Route a touches event: recognizers first, then the hit-test views,
    /// then recognition cancellation + sequence cleanup.
    public func sendEvent(_ event: UIEvent) {
        guard let touches = event.allTouches else { return }

        // 1. Gesture recognizers observe first.
        let recognizers = involvedRecognizers(touches)
        for r in recognizers where r.isEnabled {
            let mine = touches.filter { ($0.gestureRecognizers ?? []).contains { $0 === r } }
            for phase in [UITouch.Phase.began, .moved, .stationary, .ended, .cancelled] {
                let ts = mine.filter { $0.phase == phase }
                guard !ts.isEmpty else { continue }
                switch phase {
                case .began: r._touchesBegan(Set(ts), with: event)
                case .moved: r._touchesMoved(Set(ts), with: event)
                case .stationary: r.timeAdvanced(to: event.timestamp, with: event)
                case .ended: r._touchesEnded(Set(ts), with: event)
                case .cancelled: r._touchesCancelled(Set(ts), with: event)
                }
            }
        }

        // 2. Recognition side effects (cancel touches in view).
        processRecognitions(recognizers, event: event)

        // 3. Views. Group by (view, phase); skip touches a recognizer
        // already cancelled. delaysContentTouches (M7.5): a held touch-down
        // delivers nothing until it flushes — the delay deadline passing,
        // the scroll pan failing (drag along a non-scrollable axis), or the
        // touch ending (quick tap: began + ended arrive back to back). A
        // held touch the scroll pan claims is dropped silently (the view
        // never saw touchesBegan, so it gets no touchesCancelled either).
        var groups: [(view: UIView, phase: UITouch.Phase, touches: Set<UITouch>)] = []
        for t in touches.sorted(by: { $0.touchID < $1.touchID }) {
            guard let v = t.view, !t.deliveryCancelled else { continue }
            if t.beganPending {
                switch t.phase {
                case .began, .stationary:
                    continue // held
                case .moved:
                    let panFailed = t.delayingScrollView?.panGestureRecognizer._state == .failed
                    guard panFailed || event.timestamp >= t.delayDeadline else { continue }
                    t.beganPending = false
                    v.touchesBegan([t], with: event)
                case .ended:
                    t.beganPending = false
                    v.touchesBegan([t], with: event)
                case .cancelled:
                    t.beganPending = false
                    continue // never delivered — nothing to cancel
                }
            }
            if let i = groups.firstIndex(where: { $0.view === v && $0.phase == t.phase }) {
                groups[i].touches.insert(t)
            } else {
                groups.append((v, t.phase, [t]))
            }
        }
        for g in groups {
            switch g.phase {
            case .began: g.view.touchesBegan(g.touches, with: event)
            case .moved: g.view.touchesMoved(g.touches, with: event)
            case .stationary: break
            case .ended:
                g.view.touchesEnded(g.touches, with: event)
                for t in g.touches { t.endDelivered = true }
            case .cancelled: g.view.touchesCancelled(g.touches, with: event)
            }
        }

        // 4. Sequence cleanup.
        finishSequences(touches)
    }

    // MARK: Internals

    /// delaysContentTouches: deliver the held touchesBegan of every active
    /// touch whose content-touch delay has elapsed (finger resting on a row
    /// long enough — the row highlights while the finger is still down).
    func flushDelayedContentTouches(at timestamp: TimeInterval) {
        for t in activeTouches.values
        where t.beganPending && !t.deliveryCancelled && timestamp >= t.delayDeadline {
            t.beganPending = false
            guard let v = t.view else { continue }
            let event = UIEvent(timestamp: timestamp)
            event.eventTouches = [t]
            v.touchesBegan([t], with: event)
        }
    }

    func involvedRecognizers(_ touches: Set<UITouch>) -> [UIGestureRecognizer] {
        var recs: [UIGestureRecognizer] = []
        for t in touches.sorted(by: { $0.touchID < $1.touchID }) {
            for r in t.gestureRecognizers ?? [] where !recs.contains(where: { $0 === r }) {
                recs.append(r)
            }
        }
        return recs
    }

    /// A recognizer that just recognized (entered .began, or .ended straight
    /// from .possible) with cancelsTouchesInView cancels its touches'
    /// delivery to their views: the views get touchesCancelled once, and
    /// those touches deliver nothing further.
    func processRecognitions(_ recognizers: [UIGestureRecognizer], event: UIEvent) {
        for r in recognizers where r.pendingCancelTouches {
            r.pendingCancelTouches = false
            guard r.cancelsTouchesInView else { continue }
            var byView: [(view: UIView, touches: Set<UITouch>)] = []
            // Note: touches ENDING in this very event are still cancelled —
            // UIKit sends touchesCancelled (not Ended) to the view when the
            // recognizer recognizes on the lift; only touches whose end was
            // already delivered in an earlier event escape.
            for t in r.trackedTouches {
                guard let v = t.view, !t.deliveryCancelled,
                      !t.endDelivered, t.phase != .cancelled else { continue }
                t.deliveryCancelled = true
                // A touch still held by delaysContentTouches never reached
                // its view — drop it without a touchesCancelled callback.
                if t.beganPending {
                    t.beganPending = false
                    continue
                }
                if let i = byView.firstIndex(where: { $0.view === v }) {
                    byView[i].touches.insert(t)
                } else {
                    byView.append((v, [t]))
                }
            }
            for g in byView {
                g.view.touchesCancelled(g.touches, with: event)
            }
        }
    }

    /// Reset recognizers whose touch sequence has fully ended.
    func finishSequences(_ touches: Set<UITouch>) {
        for r in involvedRecognizers(touches) {
            let allDone = r.trackedTouches.allSatisfy {
                $0.phase == .ended || $0.phase == .cancelled
            }
            if allDone, !r.trackedTouches.isEmpty {
                r._sequenceEnded()
            }
        }
    }
}

// UIScrollView with UIKit-exact physics. Owner: scroll module (M7.5).
//
// Scrolling model (real UIKit / CoreAnimation semantics):
//   contentOffset IS bounds.origin — sublayers keep their frames and the
//   layer scrolls by shifting its own bounds origin. Both compositors honor
//   it: quartz's layer compositor translates by -(bounds.origin + anchor)
//   (qz_layer.cpp render_layer) and the RenderPass traversal translates
//   subview contexts by -bounds.mid. Hit testing / convert already run
//   through bounds.mid as well, so scrolled content hit-tests correctly.
//
// Physics MEASURED against real iOS UIKit (iOS 26.1, iPhone 16 simulator,
// synthetic-touch traces — golden/scroll_traces/, docs/APP_FEEL.md
// "Measured scroll physics", gated by Tools/compare/compare_scroll.py):
//   - Tracking 1:1 while dragging (per-axis, enabled by content overflow
//     or alwaysBounce*); the pan begins after a 10 pt slop and applies
//     travel − 10 pt on the recognizing event (measured exactly).
//   - Release velocity from the last ~100 ms of applied-offset samples.
//   - Deceleration: UIKit decelerationRate .normal = 0.998 per MILLISECOND:
//       v(t)  = v0 · 0.998^(1000·t)         (t seconds)
//       x(t)  = x0 + v0 · 0.499 · (1 − 0.998^(1000·t))
//     (0.499 = r/(1−r)/1000, the per-ms geometric sum), stopping dead when
//     |v| decays to 10 pt/s — landing offset x0 + (v0 ∓ 10)·0.499 matches
//     UIKit's targetContentOffset within 0.3 pt at 750–4875 pt/s.
//   - Rubber-band overscroll (Apple's formula, c = 0.55, measured exact):
//       banded = (1 − 1/(c·|d|/dim + 1)) · dim · sign(d)
//     applied to the raw overshoot d while dragging past an edge.
//   - Bounce-back: two measured regimes. Entered WITH velocity (edge impact
//     or thrown release): critically damped spring, ω = 11.0. Released from
//     a held overscroll (|v0| < 50 pt/s): overdamped spring, λ = 9.0/46.0.
//     Deceleration that reaches an edge switches to the spring with the
//     velocity at the exact (closed-form) crossing time.
//   - Scroll indicators: 2.5 pt rounded bars inset 3 pt from the edges,
//     visible while dragging/decelerating/bouncing, fading out over 0.4 s
//     (UIView.animate — same presentation clock) after the scroll settles.
//
// All time comes in through the API: dragging uses UIEvent timestamps,
// deceleration/bounce are stepped by UIWindow.tick(timestamp:) via
// `UIScrollView._stepScrollAnimations(to:)` — the same host-driven clock
// that drives UIView.animate (OpenUIKitRuntime.animationTime in openhost),
// so scripted captures are fully deterministic.
//
// Content-touch delay (delaysContentTouches, UIKit ~150 ms): implemented in
// the window's delivery pipeline (UIEvent.swift) with the hooks at the
// bottom of this file. touchesShouldCancel(in:)/canCancelContentTouches
// gate whether a recognized scroll pan cancels an already-delivered content
// touch (modern UIKit cancels control touches too — buttons/rows inside
// scroll views stop tracking when the scroll starts).

// MARK: - UIEdgeInsets

public struct UIEdgeInsets: Equatable, Sendable {
    public var top: CGFloat
    public var left: CGFloat
    public var bottom: CGFloat
    public var right: CGFloat
    public init(top: CGFloat = 0, left: CGFloat = 0,
                bottom: CGFloat = 0, right: CGFloat = 0) {
        self.top = top
        self.left = left
        self.bottom = bottom
        self.right = right
    }
    public static let zero = UIEdgeInsets()
}

// MARK: - Delegate

public protocol UIScrollViewDelegate: AnyObject {
    func scrollViewDidScroll(_ scrollView: UIScrollView)
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView)
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate: Bool)
    func scrollViewWillBeginDecelerating(_ scrollView: UIScrollView)
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView)
}

public extension UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {}
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {}
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate: Bool) {}
    func scrollViewWillBeginDecelerating(_ scrollView: UIScrollView) {}
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {}
}

// MARK: - Closed-form physics (unit-testable, no state)

public enum UIScrollPhysics {
    // All constants below are MEASURED against real iOS UIKit (iOS 26.1,
    // iPhone 16 simulator) via synthetic-touch traces — see
    // golden/scroll_traces/ and docs/APP_FEEL.md "Measured scroll physics".

    /// UIKit `UIScrollView.DecelerationRate.normal` — per-millisecond decay.
    /// MEASURED exact: v(t) fits v0·0.998^t_ms across 750–4875 pt/s flicks.
    public static let decelerationRateNormal: CGFloat = 0.998
    /// Per-second exponential rate constant: k = 1000·ln(0.998) (negative).
    public static let decelK: Double = 1000 * _ln(0.998)
    /// Total-distance factor: UIKit sums per-MILLISECOND multiplicative
    /// steps, so distance = v0·r/(1−r)/1000 = v0·0.499 — NOT the continuous
    /// integral −v0/k = v0·0.49950. MEASURED: all four landing targets match
    /// (v0 − stop)·0.499 within 0.3 pt; the integral form misses by ~5 pt.
    public static let decelDistanceFactor: Double =
        Double(decelerationRateNormal) / (1000 * (1 - Double(decelerationRateNormal)))
    /// Deceleration stops when |v| drops to this (pt/s). MEASURED: UIKit's
    /// targetContentOffset equals x0 + (v0 − 10)·0.499 (the ~5 pt tail below
    /// 10 pt/s is never delivered), and decel duration matches
    /// ln(v0/10)/|k| within 1.5%.
    public static let decelStopVelocity: CGFloat = 10

    /// v(t) = v0 · e^(k·t) = v0 · 0.998^(1000 t).
    public static func decelVelocity(v0: CGFloat, at t: Double) -> CGFloat {
        guard t > 0 else { return v0 }
        return v0 * CGFloat(_scrollExp(decelK * t))
    }

    /// x(t) = x0 + v0 · F · (1 − e^(k·t)), F = r/(1−r)/1000 = 0.499.
    public static func decelOffset(x0: CGFloat, v0: CGFloat, at t: Double) -> CGFloat {
        guard t > 0 else { return x0 }
        return x0 + v0 * CGFloat(decelDistanceFactor * (1 - _scrollExp(decelK * t)))
    }

    /// Time until |v| decays to `decelStopVelocity` (0 for tiny v0).
    public static func decelDuration(v0: CGFloat) -> Double {
        let mag = Double(v0.magnitude)
        guard mag > Double(decelStopVelocity) else { return 0 }
        return _ln(Double(decelStopVelocity) / mag) / decelK
    }

    /// Where the deceleration comes to rest: x0 + (v0 ∓ stop)·F.
    public static func decelTargetOffset(x0: CGFloat, v0: CGFloat) -> CGFloat {
        decelOffset(x0: x0, v0: v0, at: decelDuration(v0: v0))
    }

    /// Exact time at which x(t) crosses `boundary`, or nil if it never does
    /// before stopping. (Solve x0 + v0·F·(1 − e^(kt)) = boundary for t.)
    public static func decelCrossingTime(x0: CGFloat, v0: CGFloat,
                                         boundary: CGFloat) -> Double? {
        guard v0 != 0 else { return nil }
        let arg = 1 - Double(boundary - x0) / (Double(v0) * decelDistanceFactor)
        guard arg > 0 else { return nil }
        let t = _ln(arg) / decelK
        guard t >= 0, t <= decelDuration(v0: v0) else { return nil }
        return t
    }

    /// Apple's rubber-band coefficient. MEASURED exact: pointwise fits give
    /// c → 0.550 (dim = the scroll view's bounds dimension on that axis).
    public static let rubberBandCoefficient: CGFloat = 0.55

    /// Banded displacement for a raw overshoot `d` past the edge of a
    /// scroll view of size `dimension`:
    ///   (1 − 1/(c·|d|/dim + 1)) · dim · sign(d)  ==  c·d·dim/(c·|d| + dim)
    public static func rubberBand(_ d: CGFloat, dimension: CGFloat,
                                  coefficient c: CGFloat = rubberBandCoefficient) -> CGFloat {
        guard dimension > 0, d != 0 else { return 0 }
        return c * d * dimension / (c * d.magnitude + dimension)
    }

    // MARK: Bounce springs (MEASURED — two regimes)
    //
    // UIKit's bounce is NOT one spring. Measured (same traces):
    //  * Entering the bounce WITH velocity (deceleration hitting an edge, or
    //    a thrown overscroll release): critically damped, ω = 11.0 /s.
    //    Validated: impact overshoot peak = v/(ω·e) (predicted 100.5 pt vs
    //    measured 99.7 pt at v = 3005 pt/s) and settle times within 5%.
    //  * Released from a HELD overscroll (velocity ≈ 0): overdamped, decay
    //    rates λ = 9.0 /s (dominant tail) and 46.0 /s (initial transient).
    //    A critically damped spring cannot fit this curve (tail decays at a
    //    constant 9/s; critical damping would keep accelerating the decay).
    // The regime is chosen by |v0| at bounce start.

    /// Critically damped bounce frequency (used when |v0| ≥ threshold).
    public static let bounceOmega: Double = 11.0
    /// Overdamped rest-release decay rates (used when |v0| < threshold).
    public static let bounceRestLambdaSlow: Double = 9.0
    public static let bounceRestLambdaFast: Double = 46.0
    /// |v0| (pt/s) below which the rest-release (overdamped) spring is used.
    public static let bounceRestVelocityThreshold: CGFloat = 50

    /// Displacement from the target at time t for the bounce spring
    /// released at displacement x0 with velocity v0 (regime per above).
    public static func springDisplacement(x0: CGFloat, v0: CGFloat, at t: Double) -> CGFloat {
        guard t > 0 else { return x0 }
        if v0.magnitude < bounceRestVelocityThreshold {
            let (a, b) = overdampedCoefficients(x0: x0, v0: v0)
            return CGFloat(a * _scrollExp(-bounceRestLambdaSlow * t)
                         + b * _scrollExp(-bounceRestLambdaFast * t))
        }
        let w = bounceOmega
        let b = Double(v0) + w * Double(x0)
        return CGFloat((Double(x0) + b * t) * _scrollExp(-w * t))
    }

    /// d/dt of springDisplacement.
    public static func springVelocity(x0: CGFloat, v0: CGFloat, at t: Double) -> CGFloat {
        guard t > 0 else { return v0 }
        if v0.magnitude < bounceRestVelocityThreshold {
            let (a, b) = overdampedCoefficients(x0: x0, v0: v0)
            return CGFloat(-bounceRestLambdaSlow * a * _scrollExp(-bounceRestLambdaSlow * t)
                           - bounceRestLambdaFast * b * _scrollExp(-bounceRestLambdaFast * t))
        }
        let w = bounceOmega
        let b = Double(v0) + w * Double(x0)
        return CGFloat((b - w * (Double(x0) + b * t)) * _scrollExp(-w * t))
    }

    /// x(t) = A·e^(−λ1 t) + B·e^(−λ2 t) with x(0) = x0, x'(0) = v0.
    static func overdampedCoefficients(x0: CGFloat, v0: CGFloat) -> (Double, Double) {
        let l1 = bounceRestLambdaSlow, l2 = bounceRestLambdaFast
        let a = (Double(v0) + l2 * Double(x0)) / (l2 - l1)
        return (a, Double(x0) - a)
    }
}

// MARK: - UIScrollView

open class UIScrollView: UIView {
    // MARK: Content geometry

    /// The scroll position — literally the layer's bounds origin (UIKit/CA).
    public var contentOffset: CGPoint {
        get { bounds.origin }
        set { bounds.origin = newValue }
    }

    public func setContentOffset(_ offset: CGPoint, animated: Bool) {
        stopScrollAnimation()
        if animated {
            UIView.animate(withDuration: 0.25, delay: 0, options: [],
                           animations: { self.contentOffset = offset })
        } else {
            contentOffset = offset
        }
    }

    public var contentSize: CGSize = .zero {
        didSet { if contentSize != oldValue { setNeedsLayout() } }
    }
    public var contentInset: UIEdgeInsets = .zero {
        didSet { if contentInset != oldValue { setNeedsLayout() } }
    }

    // MARK: Behavior flags (UIKit defaults)

    public var isScrollEnabled = true {
        didSet { panGestureRecognizer.isEnabled = isScrollEnabled }
    }
    public var bounces = true
    public var alwaysBounceVertical = false
    public var alwaysBounceHorizontal = false
    public var showsVerticalScrollIndicator = true
    public var showsHorizontalScrollIndicator = true
    /// Wait ~150 ms (or until the scroll pan claims the gesture) before
    /// delivering touch-down to content subviews.
    public var delaysContentTouches = true
    public var canCancelContentTouches = true
    /// Per-millisecond deceleration factor (UIKit .normal).
    public var decelerationRate: CGFloat = UIScrollPhysics.decelerationRateNormal

    public weak var delegate: UIScrollViewDelegate?

    /// The content-touch delay (UIKit's is ~150 ms). Static + tunable for
    /// tests, like UIWindow.multiTapInterval.
    public static var contentTouchDelay: TimeInterval = 0.15

    /// Finger travel ALONG A SCROLLABLE AXIS (points) after which the scroll
    /// view claims a content touch away from the subview it was delivered to
    /// — the row/button gets `touchesCancelled` and its highlight fades.
    ///
    /// This is deliberately smaller than the pan's ~10 pt recognition slop:
    /// in UIKit a table row un-highlights as soon as the finger starts
    /// travelling, a moment BEFORE the content actually begins to move.
    /// Feel-tuned (like the interactive-pop velocity threshold), not
    /// oracle-measured — see docs/KNOWN_GAPS.md.
    public static var contentTouchCancelDistance: CGFloat = 5

    // MARK: State

    /// A touch has landed and the pan may still claim it.
    public private(set) var isTracking = false
    /// The pan is actively moving the content.
    public private(set) var isDragging = false
    public private(set) var isDecelerating = false

    public let panGestureRecognizer: UIPanGestureRecognizer

    public override init(frame: CGRect = .zero) {
        let pan = UIScrollViewPanGestureRecognizer()
        panGestureRecognizer = pan
        super.init(frame: frame)
        clipsToBounds = true // UIKit default for scroll views
        pan.scrollView = self
        pan.addTarget { [weak self] r in
            guard let self, let p = r as? UIScrollViewPanGestureRecognizer else { return }
            self.handlePan(p)
        }
        addGestureRecognizer(pan)
    }

    // MARK: Scrollable range

    /// Legal contentOffset range per axis (inset-adjusted, UIKit rules).
    public var minContentOffset: CGPoint {
        CGPoint(x: -contentInset.left, y: -contentInset.top)
    }
    public var maxContentOffset: CGPoint {
        CGPoint(x: max(-contentInset.left,
                       contentSize.width + contentInset.right - bounds.width),
                y: max(-contentInset.top,
                       contentSize.height + contentInset.bottom - bounds.height))
    }

    var canScrollX: Bool { maxContentOffset.x > minContentOffset.x }
    var canScrollY: Bool { maxContentOffset.y > minContentOffset.y }
    /// Axis participates in dragging at all.
    var dragsX: Bool { canScrollX || (bounces && alwaysBounceHorizontal) }
    var dragsY: Bool { canScrollY || (bounces && alwaysBounceVertical) }
    /// Axis rubber-bands/bounces past its edges.
    var bouncesX: Bool { bounces && (canScrollX || alwaysBounceHorizontal) }
    var bouncesY: Bool { bounces && (canScrollY || alwaysBounceVertical) }

    // MARK: Content-touch semantics

    /// Whether a recognized scroll pan may cancel touches already delivered
    /// to `view`. Modern UIKit cancels control touches too (rows/buttons in
    /// scroll views stop tracking when the scroll starts); override to
    /// protect a control from cancellation.
    open func touchesShouldCancel(in view: UIView) -> Bool { true }

    // MARK: Offset application (single funnel)

    /// All scrolling goes through bounds — catch every path (drag, physics,
    /// setContentOffset, user code) to keep indicators + delegate in sync.
    open override var bounds: CGRect {
        didSet {
            if bounds.origin != oldValue.origin {
                updateIndicators()
                delegate?.scrollViewDidScroll(self)
            }
        }
    }

    open override func layoutSubviews() {
        super.layoutSubviews()
        updateIndicators()
    }

    // MARK: Drag handling

    /// Baseline offset at pan recognition.
    private var dragStartOffset: CGPoint = .zero
    /// (timestamp, applied offset) samples from the last ~100 ms of drag.
    private var dragSamples: [(t: TimeInterval, offset: CGPoint)] = []
    /// Release-velocity window (UIKit uses the trailing ~100 ms of samples).
    static let velocityWindow: TimeInterval = 0.1

    func handlePan(_ pan: UIScrollViewPanGestureRecognizer) {
        switch pan.state {
        case .began:
            stopScrollAnimation()
            isDragging = true
            dragStartOffset = contentOffset
            // Absorb EXACTLY the 10 pt activation slop along the drag
            // direction. MEASURED (golden/scroll_traces/touch_calib.json):
            // UIKit's offset travel = finger travel − 10, even when the
            // recognizing event lands far past the slop circle (fast
            // flicks) — so subtract the slop from the touch-down
            // translation rather than zeroing at the recognition point.
            let tr = pan.translation(in: nil)
            let mag = (tr.x * tr.x + tr.y * tr.y).squareRoot()
            if mag > pan.activationDistance {
                let s = (mag - pan.activationDistance) / mag
                pan.setTranslation(CGPoint(x: tr.x * s, y: tr.y * s), in: nil)
            } else {
                pan.setTranslation(.zero, in: nil)
            }
            // NOTE: dragSamples is seeded by the fallthrough below (the
            // recognizing event's .changed pass records the post-slop
            // offset) — seeding it here with the PRE-recognition offset
            // would fold the slop jump into the release velocity.
            dragSamples = []
            delegate?.scrollViewWillBeginDragging(self)
            flashIndicators()
            // The recognizing event itself moves the content (UIKit: the
            // slop-adjusted translation applies immediately, not on the
            // next event — MEASURED, see touch_calib/decel traces).
            fallthrough
        case .changed:
            let tr = pan.translation(in: nil)
            var raw = CGPoint(x: dragsX ? dragStartOffset.x - tr.x : contentOffset.x,
                              y: dragsY ? dragStartOffset.y - tr.y : contentOffset.y)
            raw = appliedDragOffset(raw)
            contentOffset = raw
            recordDragSample(t: pan.lastTimestamp, offset: raw)
        case .ended, .cancelled:
            recordDragSample(t: pan.lastTimestamp, offset: contentOffset)
            isDragging = false
            let v = pan.state == .cancelled ? .zero : releaseVelocity()
            // The momentum/bounce animation starts at the LIFT time (the
            // ended event's touch timestamp), not the last move's —
            // pan.lastTimestamp deliberately stays at the last move so the
            // release-velocity window isn't diluted by the still finger.
            let tEnd = pan.trackedTouches.map(\.timestamp).max() ?? pan.lastTimestamp
            endDragging(velocity: v, at: tEnd)
        default:
            break
        }
    }

    /// Clamp + rubber-band the raw (finger-tracking) offset per axis.
    func appliedDragOffset(_ raw: CGPoint) -> CGPoint {
        let lo = minContentOffset, hi = maxContentOffset
        func axis(_ x: CGFloat, _ lo: CGFloat, _ hi: CGFloat,
                  bounces: Bool, dim: CGFloat) -> CGFloat {
            let clamped = min(max(x, lo), hi)
            let overshoot = x - clamped
            guard overshoot != 0, bounces else { return clamped }
            return clamped + UIScrollPhysics.rubberBand(overshoot, dimension: dim)
        }
        return CGPoint(x: axis(raw.x, lo.x, hi.x, bounces: bouncesX, dim: bounds.width),
                       y: axis(raw.y, lo.y, hi.y, bounces: bouncesY, dim: bounds.height))
    }

    func recordDragSample(t: TimeInterval, offset: CGPoint) {
        dragSamples.append((t, offset))
        let cutoff = t - UIScrollView.velocityWindow - 0.02
        while dragSamples.count > 2, dragSamples[0].t < cutoff {
            dragSamples.removeFirst()
        }
    }

    /// Offset velocity (pt/s) over the trailing ~100 ms of samples.
    func releaseVelocity() -> CGPoint {
        guard let last = dragSamples.last else { return .zero }
        // Oldest sample still inside the window.
        var first = dragSamples[0]
        for s in dragSamples where last.t - s.t <= UIScrollView.velocityWindow {
            first = s
            break
        }
        let dt = last.t - first.t
        guard dt > 0 else { return .zero }
        return CGPoint(x: (last.offset.x - first.offset.x) / CGFloat(dt),
                       y: (last.offset.y - first.offset.y) / CGFloat(dt))
    }

    func endDragging(velocity v: CGPoint, at time: TimeInterval? = nil) {
        let now = time ?? dragSamples.last?.t ?? OpenUIKitRuntime.animationTime
        dragSamples.removeAll()
        let lo = minContentOffset, hi = maxContentOffset
        let off = contentOffset

        xAnim = makeReleaseAxisAnim(x: off.x, v: v.x, lo: lo.x, hi: hi.x,
                                    scrolls: dragsX, bouncesAxis: bouncesX, at: now)
        yAnim = makeReleaseAxisAnim(x: off.y, v: v.y, lo: lo.y, hi: hi.y,
                                    scrolls: dragsY, bouncesAxis: bouncesY, at: now)

        let decelerates = xAnim != nil || yAnim != nil
        delegate?.scrollViewDidEndDragging(self, willDecelerate: decelerates)
        if decelerates {
            isDecelerating = true
            delegate?.scrollViewWillBeginDecelerating(self)
            UIScrollView.registerAnimating(self)
        } else {
            settle()
        }
    }

    func makeReleaseAxisAnim(x: CGFloat, v: CGFloat, lo: CGFloat, hi: CGFloat,
                             scrolls: Bool, bouncesAxis: Bool,
                             at now: TimeInterval) -> AxisAnim? {
        guard scrolls else { return nil }
        if x < lo || x > hi {
            // Released while overscrolled: spring back to the near boundary,
            // carrying the release velocity.
            let target = x < lo ? lo : hi
            return AxisAnim(mode: .bounce, start: now, x0: x - target, v0: v,
                            target: target, lo: lo, hi: hi, bounces: bouncesAxis)
        }
        guard v.magnitude > UIScrollPhysics.decelStopVelocity else { return nil }
        return AxisAnim(mode: .decelerate, start: now, x0: x, v0: v,
                        target: 0, lo: lo, hi: hi, bounces: bouncesAxis)
    }

    // MARK: Momentum / bounce animation

    struct AxisAnim {
        enum Mode { case decelerate, bounce }
        var mode: Mode
        var start: TimeInterval
        /// decelerate: offset at start. bounce: displacement from target.
        var x0: CGFloat
        var v0: CGFloat
        /// bounce: the boundary offset being sprung to.
        var target: CGFloat
        var lo: CGFloat
        var hi: CGFloat
        var bounces: Bool
    }

    var xAnim: AxisAnim?
    var yAnim: AxisAnim?

    /// Deceleration/bounce is over when the spring displacement AND velocity
    /// are visually zero.
    static let springSettleDisplacement: CGFloat = 0.05
    static let springSettleVelocity: CGFloat = 0.5

    /// Advance one axis to time `t`. Returns (offset, finished).
    static func stepAxis(_ a: inout AxisAnim, to t: TimeInterval) -> (CGFloat, Bool) {
        let dt = max(0, t - a.start)
        switch a.mode {
        case .decelerate:
            // Edge crossing: switch to the bounce spring at the EXACT
            // crossing time (closed form, tick-cadence independent).
            let boundary: CGFloat? = a.v0 < 0 ? (a.x0 >= a.lo ? a.lo : nil)
                                             : (a.x0 <= a.hi ? a.hi : nil)
            if let b = boundary,
               let tc = UIScrollPhysics.decelCrossingTime(x0: a.x0, v0: a.v0, boundary: b),
               dt >= tc {
                if a.bounces {
                    // Hand off at the EXACT crossing time with the carried
                    // velocity (start shifts by tc — tick-cadence free).
                    let vc = UIScrollPhysics.decelVelocity(v0: a.v0, at: tc)
                    a = AxisAnim(mode: .bounce, start: a.start + tc, x0: 0, v0: vc,
                                 target: b, lo: a.lo, hi: a.hi, bounces: a.bounces)
                    return stepAxis(&a, to: t)
                }
                return (b, true) // no bounce: clamp dead at the edge
            }
            let dur = UIScrollPhysics.decelDuration(v0: a.v0)
            if dt >= dur {
                return (UIScrollPhysics.decelOffset(x0: a.x0, v0: a.v0, at: dur), true)
            }
            return (UIScrollPhysics.decelOffset(x0: a.x0, v0: a.v0, at: dt), false)
        case .bounce:
            let d = UIScrollPhysics.springDisplacement(x0: a.x0, v0: a.v0, at: dt)
            let v = UIScrollPhysics.springVelocity(x0: a.x0, v0: a.v0, at: dt)
            if d.magnitude < springSettleDisplacement,
               v.magnitude < springSettleVelocity {
                return (a.target, true)
            }
            return (a.target + d, false)
        }
    }

    /// Advance the scroll animation to `time` (host clock — the same clock
    /// as UIView.animate). Called from UIWindow.tick via _stepScrollAnimations.
    func stepScrollAnimation(to time: TimeInterval) {
        guard xAnim != nil || yAnim != nil else { return }
        var off = contentOffset
        if var a = xAnim {
            let (x, done) = UIScrollView.stepAxis(&a, to: time)
            off.x = x
            xAnim = done ? nil : a
        }
        if var a = yAnim {
            let (y, done) = UIScrollView.stepAxis(&a, to: time)
            off.y = y
            yAnim = done ? nil : a
        }
        contentOffset = off
        if xAnim == nil && yAnim == nil {
            isDecelerating = false
            delegate?.scrollViewDidEndDecelerating(self)
            settle()
        }
    }

    /// Cancel any momentum/bounce, freezing the offset where it is.
    public func stopScrollAnimation() {
        if xAnim != nil || yAnim != nil {
            xAnim = nil
            yAnim = nil
            isDecelerating = false
        }
    }

    func settle() {
        fadeIndicators()
    }

    // MARK: Global animation registry (host clock stepping)

    private struct WeakScrollView { weak var view: UIScrollView? }
    private static var animating: [WeakScrollView] = []

    static func registerAnimating(_ sv: UIScrollView) {
        animating.removeAll { $0.view == nil }
        if !animating.contains(where: { $0.view === sv }) {
            animating.append(WeakScrollView(view: sv))
        }
    }

    /// Advance every decelerating/bouncing scroll view to `time`. The
    /// window calls this from tick(timestamp:) — the host's frame clock.
    public static func _stepScrollAnimations(to time: TimeInterval) {
        guard !animating.isEmpty else { return }
        let live = animating.compactMap { $0.view }
        for sv in live { sv.stepScrollAnimation(to: time) }
        animating.removeAll { $0.view == nil || ($0.view!.xAnim == nil && $0.view!.yAnim == nil) }
    }

    /// Any scroll view is still decelerating/bouncing (host redraw hint).
    public static var _hasActiveScrollAnimations: Bool {
        animating.contains { $0.view != nil && ($0.view!.xAnim != nil || $0.view!.yAnim != nil) }
    }

    // MARK: Touch-pipeline hooks (called by UIWindow — see UIEvent.swift)

    /// Nearest enclosing scroll view of `view` (including itself).
    static func enclosingScrollView(of view: UIView?) -> UIScrollView? {
        var v = view
        while let cur = v {
            if let sv = cur as? UIScrollView { return sv }
            v = cur.superview
        }
        return nil
    }

    /// Nearest enclosing modal page sheet, if this view lives inside one.
    static func enclosingPageSheet(of view: UIView?) -> _UIPageSheetView? {
        var v = view
        while let cur = v {
            if let sheet = cur as? _UIPageSheetView { return sheet }
            v = cur.superview
        }
        return nil
    }

    /// A touch landed inside the scroll view (on it or a descendant).
    /// Returns true when the touch was a scroll-catch (finger stopping a
    /// deceleration) — such touches are consumed and never reach content.
    func touchBeganInContent() -> Bool {
        isTracking = true
        let wasAnimating = xAnim != nil || yAnim != nil
        if wasAnimating {
            stopScrollAnimation()
            flashIndicators() // stay visible; drag likely follows
        }
        return wasAnimating
    }

    func touchSequenceEnded() {
        isTracking = false
    }

    // MARK: Scroll indicators

    /// 2.5 pt bar, 3 pt inset from the trailing/bottom edge and 3 pt from
    /// the track ends (APP_FEEL).
    static let indicatorThickness: CGFloat = 2.5
    static let indicatorInset: CGFloat = 3
    static let indicatorMinLength: CGFloat = 36
    /// Indicator fade-out duration after the scroll settles.
    static let indicatorFadeDuration: Double = 0.4

    var verticalIndicator: UIView?
    var horizontalIndicator: UIView?
    /// True between flashIndicators() and fadeIndicators().
    var indicatorsVisible = false

    /// Lazily create an indicator bar (lazy so static scenes never gain
    /// extra subviews — layout dumps stay clean, like UIKit's lazy ones).
    func makeIndicator() -> UIView {
        let bar = UIView()
        bar.isUserInteractionEnabled = false
        bar.layer.cornerRadius = UIScrollView.indicatorThickness / 2
        let dark = traitCollection.userInterfaceStyle == .dark
        bar.backgroundColor = dark
            ? UIColor(red: 1, green: 1, blue: 1, alpha: 0.35)
            : UIColor(red: 0, green: 0, blue: 0, alpha: 0.35)
        bar.alpha = 0
        addSubview(bar)
        return bar
    }

    func flashIndicators() {
        indicatorsVisible = true
        if showsVerticalScrollIndicator, canScrollY, verticalIndicator == nil {
            verticalIndicator = makeIndicator()
        }
        if showsHorizontalScrollIndicator, canScrollX, horizontalIndicator == nil {
            horizontalIndicator = makeIndicator()
        }
        for bar in [verticalIndicator, horizontalIndicator] {
            guard let bar else { continue }
            bar.removeAllAnimations()
            bar.alpha = 1
        }
        updateIndicators()
    }

    func fadeIndicators() {
        guard indicatorsVisible else { return }
        indicatorsVisible = false
        for bar in [verticalIndicator, horizontalIndicator] {
            guard let bar, bar.alpha > 0 else { continue }
            UIView.animate(withDuration: UIScrollView.indicatorFadeDuration,
                           delay: 0, options: .curveLinear,
                           animations: { bar.alpha = 0 })
        }
    }

    /// Position the bars for the current offset. Bars are subviews living in
    /// the scrolled coordinate space, so their frames are pinned to the
    /// VISIBLE rect (bounds.origin + viewport-relative position).
    func updateIndicators() {
        let inset = UIScrollView.indicatorInset
        let thick = UIScrollView.indicatorThickness
        let off = contentOffset
        let lo = minContentOffset, hi = maxContentOffset

        if let bar = verticalIndicator {
            let range = hi.y - lo.y
            let contentLen = contentSize.height + contentInset.top + contentInset.bottom
            let track = bounds.height - 2 * inset
            if range > 0, contentLen > 0, track > 0 {
                var len = max(UIScrollView.indicatorMinLength,
                              track * min(1, bounds.height / contentLen))
                // Overscroll: the bar compresses by the overshoot, pinned to
                // its end of the track (UIKit behavior).
                let overshoot = off.y < lo.y ? lo.y - off.y
                              : off.y > hi.y ? off.y - hi.y : 0
                len = max(thick * 2, len - overshoot)
                let p = min(1, max(0, (off.y - lo.y) / range))
                let y = inset + (track - len) * p
                bar.frame = CGRect(x: off.x + bounds.width - inset - thick,
                                   y: off.y + y, width: thick, height: len)
                bar.isHidden = false
            } else {
                bar.isHidden = true
            }
        }
        if let bar = horizontalIndicator {
            let range = hi.x - lo.x
            let contentLen = contentSize.width + contentInset.left + contentInset.right
            let track = bounds.width - 2 * inset
            if range > 0, contentLen > 0, track > 0 {
                var len = max(UIScrollView.indicatorMinLength,
                              track * min(1, bounds.width / contentLen))
                let overshoot = off.x < lo.x ? lo.x - off.x
                              : off.x > hi.x ? off.x - hi.x : 0
                len = max(thick * 2, len - overshoot)
                let p = min(1, max(0, (off.x - lo.x) / range))
                let x = inset + (track - len) * p
                bar.frame = CGRect(x: off.x + x,
                                   y: off.y + bounds.height - inset - thick,
                                   width: len, height: thick)
                bar.isHidden = false
            } else {
                bar.isHidden = true
            }
        }
    }
}

// MARK: - Scroll pan recognizer

/// UIScrollView's pan: standard pan slop/velocity behavior, plus the
/// scroll-specific begin gates — axis eligibility (the drag must move along
/// a scrollable/bounceable axis) and content-touch cancellation policy
/// (canCancelContentTouches / touchesShouldCancel(in:)).
public final class UIScrollViewPanGestureRecognizer: UIPanGestureRecognizer {
    weak var scrollView: UIScrollView?

    /// Set once this pan has taken its touches away from the content
    /// subviews they were delivered to (see `claimContentTouches`).
    private var claimedContentTouches = false

    public override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
        if _state == .possible, let sv = scrollView {
            let p = location(in: nil)
            let dx = p.x - startLocation.x, dy = p.y - startLocation.y
            if (dx * dx + dy * dy).squareRoot() > activationDistance,
               !allowBegin(sv, dx: dx, dy: dy) {
                state = .failed
            } else if _state == .possible {
                claimContentTouches(sv, dx: dx, dy: dy)
            }
        }
        super.touchesMoved(touches, with: event)
    }

    /// Take the touches away from the content subviews as soon as the finger
    /// is clearly dragging along a scrollable axis, WITHOUT waiting for the
    /// pan's own ~10 pt slop: the row/button gets `touchesCancelled` in this
    /// very event (UIWindow.processRecognitions consumes
    /// `pendingCancelTouches` right after the recognizers observe), so its
    /// highlight is already fading when the content starts to move. UIKit
    /// un-highlights this eagerly; keeping the highlight through the whole
    /// slop window was the "row press states don't cancel on significant
    /// vertical finger travel" gap in docs/APP_FEEL.md.
    ///
    /// The pan itself keeps its normal threshold — claiming the touch does
    /// not start the scroll, and a claimed touch still feeds this recognizer.
    private func claimContentTouches(_ sv: UIScrollView, dx: CGFloat, dy: CGFloat) {
        guard !claimedContentTouches else { return }
        // Travel along the dominant axis only: a horizontal wiggle in a
        // vertical scroll view is not a drag and must keep the highlight.
        let axisTravel = Swift.max(dx.magnitude, dy.magnitude)
        guard axisTravel > UIScrollView.contentTouchCancelDistance,
              allowBegin(sv, dx: dx, dy: dy) else { return }
        // Nothing to steal unless a touch actually reached a content view.
        guard trackedTouches.contains(where: {
            $0.view !== sv && $0.view != nil && !$0.deliveryCancelled
        }) else { return }
        claimedContentTouches = true
        pendingCancelTouches = true
    }

    public override func reset() {
        claimedContentTouches = false
        super.reset()
    }

    func allowBegin(_ sv: UIScrollView, dx: CGFloat, dy: CGFloat) -> Bool {
        // Sheet hand-off (MEASURED, iOS 26.1): a scroll view inside a page
        // sheet, already at the top of its content, yields a DOWNWARD drag to
        // the sheet — the sheet moves and contentOffset stays at 0. Mirror of
        // _UISheetPanGestureRecognizer.allowBegin (no require(toFail:), so
        // both sides state the rule).
        if dy > 0, dy.magnitude > dx.magnitude,
           sv.contentOffset.y <= sv.minContentOffset.y,
           UIScrollView.enclosingPageSheet(of: sv) != nil {
            return false
        }
        // Axis gate: the dominant movement direction must be scrollable.
        let allowX = sv.dragsX, allowY = sv.dragsY
        if !allowX && !allowY { return false }
        if dx.magnitude > dy.magnitude { if !allowX { return false } }
        else { if !allowY { return false } }
        // Content-touch cancellation gate: a touch whose touch-down was
        // already DELIVERED to a content subview may only be stolen when
        // canCancelContentTouches and touchesShouldCancel(in:) allow it.
        // (Touches still held by the delaysContentTouches window were never
        // delivered — nothing to cancel, the pan is free to begin.)
        for t in trackedTouches {
            guard let v = t.view, v !== sv, !t.beganPending,
                  UIScrollView.enclosingScrollView(of: v) === sv else { continue }
            if !sv.canCancelContentTouches || !sv.touchesShouldCancel(in: v) {
                return false
            }
        }
        return true
    }
}

// MARK: - exp helper (no Foundation)

/// e^x for any x (range-reduced Taylor, ~1e-12 over the physics ranges).
func _scrollExp(_ x: Double) -> Double {
    if x == 0 { return 1 }
    let neg = x < 0
    var y = x.magnitude
    var k = 0
    while y > 0.5 { y /= 2; k += 1 }
    var term = 1.0
    var sum = 1.0
    for i in 1...16 {
        term *= y / Double(i)
        sum += term
    }
    for _ in 0..<k { sum *= sum }
    return neg ? 1 / sum : sum
}

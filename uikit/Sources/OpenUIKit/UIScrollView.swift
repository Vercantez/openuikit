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


// On the Objective-C implementation route (Darwin) `UIEdgeInsets` is the C
// struct declared in Sources/OpenUIKitObjC/include/UIGeometry.h, so that a
// header can declare `-_defaultBaseLayoutMargins`; ObjCImplementation.swift
// adds the same `.zero`, Equatable and defaulted initializer as extensions.
#if !OPENUIKIT_OBJC_IMPLEMENTATION
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
#endif

// MARK: - Delegate

@preconcurrency @MainActor
public protocol UIScrollViewDelegate: AnyObject {
    func scrollViewDidScroll(_ scrollView: UIScrollView)
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView)
    /// M13. UIKit hands the delegate the deceleration's natural landing
    /// point and lets it write a different one back — this is how paging and
    /// snapping are built. Honoured: see `UIScrollView.endDragging`.
    func scrollViewWillEndDragging(_ scrollView: UIScrollView,
                                   withVelocity velocity: CGPoint,
                                   targetContentOffset: UnsafeMutablePointer<CGPoint>)
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate: Bool)
    func scrollViewWillBeginDecelerating(_ scrollView: UIScrollView)
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView)
    /// Fires when an ANIMATED `setContentOffset` / `scrollRectToVisible`
    /// finishes (M13).
    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView)
    func scrollViewDidChangeAdjustedContentInset(_ scrollView: UIScrollView)
    /// Declared for source compatibility. There is no status-bar tap to
    /// trigger scroll-to-top here, so neither member is ever called
    /// (docs/KNOWN_GAPS.md).
    func scrollViewShouldScrollToTop(_ scrollView: UIScrollView) -> Bool
    func scrollViewDidScrollToTop(_ scrollView: UIScrollView)
    /// Zoom callbacks. Programmatic animated zoom uses the same host-driven
    /// UIView animation clock as scrolling and property animations.
    func viewForZooming(in scrollView: UIScrollView) -> UIView?
    func scrollViewDidZoom(_ scrollView: UIScrollView)
    func scrollViewWillBeginZooming(_ scrollView: UIScrollView, with view: UIView?)
    func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?,
                                 atScale scale: CGFloat)
}

public extension UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {}
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {}
    func scrollViewWillEndDragging(_ scrollView: UIScrollView,
                                   withVelocity velocity: CGPoint,
                                   targetContentOffset: UnsafeMutablePointer<CGPoint>) {}
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate: Bool) {}
    func scrollViewWillBeginDecelerating(_ scrollView: UIScrollView) {}
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {}
    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {}
    func scrollViewDidChangeAdjustedContentInset(_ scrollView: UIScrollView) {}
    func scrollViewShouldScrollToTop(_ scrollView: UIScrollView) -> Bool { true }
    func scrollViewDidScrollToTop(_ scrollView: UIScrollView) {}
    func viewForZooming(in scrollView: UIScrollView) -> UIView? { nil }
    func scrollViewDidZoom(_ scrollView: UIScrollView) {}
    func scrollViewWillBeginZooming(_ scrollView: UIScrollView, with view: UIView?) {}
    func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?,
                                 atScale scale: CGFloat) {}
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

    /// Inverse of `decelTargetOffset`: the release velocity whose
    /// deceleration comes to rest exactly at `target`. Used to honour a
    /// `scrollViewWillEndDragging` retarget (M13). Returns 0 when the
    /// distance is too small for the curve to express (|v0| would fall under
    /// the stop velocity) — the caller then jumps to the target.
    public static func velocityToLand(from x0: CGFloat, at target: CGFloat) -> CGFloat {
        let d = target - x0
        guard d != 0 else { return 0 }
        let v = CGFloat(Double(d) / decelDistanceFactor)
        let signed = v + (d > 0 ? decelStopVelocity : -decelStopVelocity)
        return signed.magnitude <= decelStopVelocity ? 0 : signed
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

@preconcurrency @MainActor
open class UIScrollView: UIView {
    public enum KeyboardDismissMode: Sendable {
        case none
        case onDrag
        case interactive
        case onDragWithAccessory
    }

    // MARK: Content geometry

    /// The scroll position — literally the layer's bounds origin (UIKit/CA).
    public var contentOffset: CGPoint {
        get { bounds.origin }
        set { bounds.origin = newValue }
    }

    /// MEASURED pager-clock probe + Pager fling, iPhone SE 2x / iOS 26.1:
    /// cosine ease-in-out over 0.3 s (n=8:165.5 n=16:388 n=30:400).
    /// Catalyst keeps cubic 0.25.
    static var animatedContentOffsetDuration: Double {
        OpenUIKitRuntime.systemFontCut == .iOS ? 0.3 : 0.25
    }

    public func setContentOffset(_ offset: CGPoint, animated: Bool) {
        stopScrollAnimation()
        var offset = offset
        // MEASURED Tabs t7000 / t7000.xxxl / t7000.ax1: see
        // `UINavigationBar.hideOnScrollContentBump`. Inactive search
        // only — Notes t5000 types into an active search and must not
        // add the 60 pt hide-on-scroll slot.
        if OpenUIKitRuntime.systemFontCut == .iOS,
           let nav = _scrollObserver as? UINavigationController {
            offset.y += nav.navigationBar.hideOnScrollContentBump(requestedY: offset.y)
        }
        if animated {
            UIView.animateScrollCurve(
                withDuration: UIScrollView.animatedContentOffsetDuration,
                animations: { self.contentOffset = offset },
                completion: { [weak self] _ in
                               guard let self else { return }
                               // CA removes the bounds animation on completion;
                               // without this a later model change stays pinned
                               // at `to` (Pager t1200 / t3500, iPhone SE 2x).
                               self._removeFinishedAnimations(
                                   at: OpenUIKitRuntime.animationTime)
                               self.delegate?.scrollViewDidEndScrollingAnimation(self)
                           })
        } else {
            contentOffset = offset
        }
    }

    public var contentSize: CGSize = .zero {
        didSet { if contentSize != oldValue { setNeedsLayout() } }
    }
    public var contentInset: UIEdgeInsets = .zero {
        didSet {
            guard contentInset != oldValue else { return }
            // MEASURED 2026-09-04 (Tools/oracle2/realappprobe, iOS 26.1): a
            // scroll view whose content sat at the top keeps it at the top
            // when the inset grows — the app sets contentInset.top = 12 and
            // UIKit reports contentOffset (0, -12), adjustedContentInset
            // [12, 0, 0, 0]; the content is drawn 12 pt down. The port used
            // to leave the offset at 0 and draw the content flush.
            var o = contentOffset
            if o.y <= -oldValue.top { o.y = -contentInset.top }
            if o.x <= -oldValue.left { o.x = -contentInset.left }
            if o != contentOffset { contentOffset = o }
            setNeedsLayout()
        }
    }
    /// Effective viewport inset after the view hierarchy's safe area is
    /// incorporated. This portable host currently models UIKit's automatic
    /// adjustment mode, the behavior used by embedded browser shells.
    ///
    /// Under the iOS cut the keyboard overlap is folded in too. MEASURED
    /// Forms t1200, iPhone SE 2x, iOS 26.1: focusing a UITextField in a
    /// grouped UITableViewController leaves `contentInset` [0,0,0,0] and
    /// `safeAreaInsets.bottom` 0, but `adjustedContentInset.bottom` goes
    /// 0 → **260**. The software keyboard is a separate window (the app
    /// window's drawHierarchy does not include it); 260 pt is the overlap
    /// onto this 667 pt window. t200 (unfocused) reads bottom 0.
    public var adjustedContentInset: UIEdgeInsets {
        UIEdgeInsets(
            top: contentInset.top + safeAreaInsets.top,
            left: contentInset.left + safeAreaInsets.left,
            bottom: contentInset.bottom + safeAreaInsets.bottom + iOSKeyboardAvoidanceBottom,
            right: contentInset.right + safeAreaInsets.right
        )
    }

    /// iPhone SE (3rd gen) default keyboard + suggestion bar, measured as
    /// the delta in `adjustedContentInset.bottom` (Forms t1200 vs t200).
    /// Pad: Forms-ipad t1200, iPad (A16) 820×1180 @2x / iOS 26.1: table
    /// `adjustedContentInset.bottom` rest **25** (window SA) → focused
    /// **337**. Overlap = 337 − 25 = **312**. Phone portrait stays 260;
    /// compact-height (SE landscape) is 206 (Forms t1200.landscape).
    static var iOSKeyboardOverlap: CGFloat {
        if OpenUIKitRuntime.systemFontCut == .iOS,
           (UITraitCollection.current.userInterfaceIdiom == .pad
            || UIDevice.current.userInterfaceIdiom == .pad) {
            return 312
        }
        return _UIKeyboardChrome.currentOverlap
    }

    var iOSKeyboardAvoidanceBottom: CGFloat {
        guard OpenUIKitRuntime.systemFontCut == .iOS else { return 0 }
        guard let responder = window?.firstResponder else { return 0 }
        guard responder is UIKeyInput else { return 0 }
        // The editor itself is often a UIScrollView (UITextView). The
        // 260 pt is applied to an ENCLOSING scroll view (the table), not
        // to the editor — Forms t1200's UITextView keeps
        // adjustedContentInset [0,0,0,0] while the table reads bottom 260.
        var node: UIView? = (responder as? UIView)?.superview
        while let cur = node {
            if cur === self { return UIScrollView.iOSKeyboardOverlap }
            node = cur.superview
        }
        // A UISearchTextField lives in the navigation bar, not inside the
        // table. MEASURED Tabs t4000, iPhone SE 2x / iOS 26.1: focusing
        // the search controller leaves `adjustedContentInset.bottom` **83**
        // (the tab bar), not the 260 keyboard overlap — the keyboard is a
        // separate window (docs/ORACLE_FLOW.md). Do not apply 260 here.
        return 0
    }
    public var verticalScrollIndicatorInsets: UIEdgeInsets = .zero {
        didSet { if verticalScrollIndicatorInsets != oldValue { updateIndicators() } }
    }
    public var horizontalScrollIndicatorInsets: UIEdgeInsets = .zero {
        didSet { if horizontalScrollIndicatorInsets != oldValue { updateIndicators() } }
    }

    /// Storage for `refreshControl` (the API lives in UIRefreshControl.swift,
    /// which owns the control's whole measured model).
    var _refreshControl: UIRefreshControl?

    // MARK: Behavior flags (UIKit defaults)

    public var isScrollEnabled = true {
        didSet { panGestureRecognizer.isEnabled = isScrollEnabled }
    }
    public var bounces = true
    public var alwaysBounceVertical = false
    public var alwaysBounceHorizontal = false
    /// When true, a finger-flick lands on a multiple of `bounds.width`
    /// (horizontal) / `bounds.height` (vertical). Programmatic
    /// `setContentOffset(animated:)` still goes to the requested offset;
    /// the paging snap is the deceleration target. Default false, matching
    /// UIKit. The curve itself is measured from Pager `fling` (iPhone SE 2x).
    public var isPagingEnabled = false
    public var showsVerticalScrollIndicator = true
    public var showsHorizontalScrollIndicator = true

    public enum IndicatorStyle: Int, Sendable { case `default`, black, white }
    /// `.default` follows the trait collection (what ``makeIndicator`` did
    /// unconditionally before); `.black`/`.white` pin the bar's colour, which
    /// is how an app with its own theme system keeps the indicator legible
    /// over a background UIKit cannot see.
    public var indicatorStyle: IndicatorStyle = .default {
        didSet {
            guard indicatorStyle != oldValue else { return }
            for bar in [verticalIndicator, horizontalIndicator].compactMap({ $0 }) {
                bar.backgroundColor = indicatorColor()
            }
        }
    }
    /// Wait ~150 ms (or until the scroll pan claims the gesture) before
    /// delivering touch-down to content subviews.
    public var delaysContentTouches = true
    public var canCancelContentTouches = true
    public var keyboardDismissMode: KeyboardDismissMode = .none
    /// Per-millisecond deceleration factor (UIKit .normal).
    public var decelerationRate: CGFloat = UIScrollPhysics.decelerationRateNormal

    /// Bounds for programmatic zoom. OpenUIKit currently provides the
    /// delegate-selected zoom view and programmatic scaling path; pinch input
    /// is a separate gesture surface.
    public var minimumZoomScale: CGFloat = 1 {
        didSet {
            if minimumZoomScale > maximumZoomScale {
                maximumZoomScale = minimumZoomScale
            }
            if _zoomScale < minimumZoomScale { setZoomScale(minimumZoomScale, animated: false) }
        }
    }
    public var maximumZoomScale: CGFloat = 1 {
        didSet {
            if maximumZoomScale < minimumZoomScale {
                minimumZoomScale = maximumZoomScale
            }
            if _zoomScale > maximumZoomScale { setZoomScale(maximumZoomScale, animated: false) }
        }
    }
    private var _zoomScale: CGFloat = 1
    public var zoomScale: CGFloat {
        get { _zoomScale }
        set { setZoomScale(newValue, animated: false) }
    }
    public private(set) var isZooming = false

    public weak var delegate: UIScrollViewDelegate?

    /// UIKit-internal scroll observation, alongside (never instead of) the
    /// app's `delegate`. UIKit's own chrome — the large-title navigation bar
    /// is the one that matters here — tracks a content scroll view without
    /// occupying the single public delegate slot, so a UITableViewController
    /// that is its own delegate keeps receiving every callback once it is
    /// pushed. MEASURED 2026-09-04, NavFlow conformance app, iPhone SE 2x:
    /// real iOS honours `heightForRowAt` (44 pt rows) inside a large-title
    /// nav controller; the port fell back to the 53 pt default because the
    /// bar had taken the delegate.
    weak var _scrollObserver: UIScrollViewDelegate?

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

    public override init(frame: CGRect) {
        let pan = UIScrollViewPanGestureRecognizer()
        panGestureRecognizer = pan
        super.init(frame: frame)
        configurePanGesture(pan)
    }

    public required init?(coder: NSCoder) {
        let pan = UIScrollViewPanGestureRecognizer()
        panGestureRecognizer = pan
        super.init(coder: coder)
        configurePanGesture(pan)
    }

    private func configurePanGesture(_ pan: UIScrollViewPanGestureRecognizer) {
        clipsToBounds = true // UIKit default for scroll views
        pan.scrollView = self
        pan.addTarget { [weak self] r in
            guard let self, let p = r as? UIScrollViewPanGestureRecognizer else { return }
            self.handlePan(p)
        }
        addGestureRecognizer(pan)
    }

    /// Scale the delegate's zoom view. Animated changes are genuine UIView
    /// transform animations and therefore advance on `UIWindow.tick`.
    public func setZoomScale(_ scale: CGFloat, animated: Bool) {
        let lower = min(minimumZoomScale, maximumZoomScale)
        let upper = max(minimumZoomScale, maximumZoomScale)
        let target = min(upper, max(lower, scale))
        guard target != _zoomScale else { return }
        let zoomView = delegate?.viewForZooming(in: self)
        _zoomScale = target

        let apply = {
            zoomView?.transform = CGAffineTransform(scaleX: target, y: target)
            self.delegate?.scrollViewDidZoom(self)
        }
        guard animated else {
            apply()
            return
        }

        zoomView?.removeAllAnimations()
        isZooming = true
        delegate?.scrollViewWillBeginZooming(self, with: zoomView)
        UIView.animate(withDuration: 0.25, delay: 0,
                       options: [.beginFromCurrentState, .allowUserInteraction],
                       animations: apply,
                       completion: { [weak self, weak zoomView] _ in
            guard let self else { return }
            self.isZooming = false
            self.delegate?.scrollViewDidEndZooming(self, with: zoomView,
                                                   atScale: self._zoomScale)
        })
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
                _layoutRefreshControl()
                if let rc = _refreshControl, isDragging {
                    rc._scrollDidDrag(to: bounds.origin.y, topEdge: _refreshTopEdge)
                }
                updateIndicators()
                delegate?.scrollViewDidScroll(self)
                _scrollObserver?.scrollViewDidScroll(self)
            }
        }
    }

    // MARK: Auto Layout guides (M14)

    var _contentLayoutGuide: UILayoutGuide?
    var _frameLayoutGuide: UILayoutGuide?

    /// UIKit's `contentLayoutGuide`. Constraints from the scroll view's
    /// subviews to this guide are what size `contentSize` — the modern
    /// "scroll view with Auto Layout" recipe, and the reason a real app's
    /// scrolling screen has any content height at all. The guide's origin is
    /// the content origin and its size is solved; `layoutSubviews` adopts the
    /// solved size (see AutoLayout/LayoutEngine.swift).
    public var contentLayoutGuide: UILayoutGuide {
        if let g = _contentLayoutGuide { return g }
        let g = UILayoutGuide(kind: .scrollContent, owningView: self)
        _contentLayoutGuide = g
        return g
    }

    /// UIKit's `frameLayoutGuide`: the scroll view's own frame, in content
    /// coordinates. Pinning a subview's width to it is how apps say "as wide
    /// as the scroll view, however tall the content is".
    public var frameLayoutGuide: UILayoutGuide {
        if let g = _frameLayoutGuide { return g }
        let g = UILayoutGuide(kind: .scrollFrame, owningView: self)
        _frameLayoutGuide = g
        return g
    }

    open override func layoutSubviews() {
        super.layoutSubviews()
        // A solved content guide owns contentSize (UIKit derives it the same
        // way). Only when the app actually took the guide out.
        if let g = _contentLayoutGuide {
            let solved = g.layoutFrame.size
            if solved != .zero, solved != contentSize { contentSize = solved }
        }
        _layoutRefreshControl()
        updateIndicators()
    }

    open override func safeAreaInsetsDidChange() {
        let previous = adjustedSafeAreaTop
        adjustedSafeAreaTop = safeAreaInsets.top
        super.safeAreaInsetsDidChange()
        let newTop = safeAreaInsets.top
        if newTop != previous {
            if OpenUIKitRuntime.systemFontCut == .iOS,
               newTop < previous,
               !isDragging, !isTracking, !isDecelerating {
                // MEASURED 2026-09-04, probe_collapse_rebase + Feed t2800,
                // iPhone SE 2x / iOS 26.1. When safeAreaInsets.top shrinks
                // and the scroll view is not tracking, contentOffset.y
                // grows by the same delta so the distance from rest is
                // unchanged:
                //   requested y >= −64 (collapse d ≥ 52) → actual = y + 52
                //   setContentOffset(300) → 352, adj 116 → 64
                //   y = −65 (d = 51) stays −65, adj 116 (still expanded)
                //   already-collapsed set(160) stays 160 (no inset change)
                // A plain UIScrollView with additionalSafeAreaInsets
                // 116 → 64 at offset 300 also lands on 352 — the rule is
                // the inset shrink, not the large-title bar itself.
                // Finger-down pans skip this: a +52 jump under the finger
                // at d = 52 is not what the 1:1 title translation does.
                contentOffset.y += previous - newTop
            } else if contentOffset.y <= -(previous + contentInset.top) {
                // Content resting at the top stays at the top when the
                // safe area grows — the same rule `contentInset`'s setter
                // applies. MEASURED (realapp_storage_light, iPhone 16 /
                // iOS 26.1): no contentInset, yet UIKit reports offset
                // (0, −59) and adjustedContentInset [59, 0, 34, 0].
                contentOffset.y = -(newTop + contentInset.top)
            }
        }
        delegate?.scrollViewDidChangeAdjustedContentInset(self)
        setNeedsLayout()
    }

    /// `safeAreaInsets.top` as of the last `safeAreaInsetsDidChange`, so the
    /// hook can tell whether the content was resting against the old inset.
    private var adjustedSafeAreaTop: CGFloat = 0

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
            if keyboardDismissMode != .none {
                _ = window?.firstResponder?.resignFirstResponder()
            }
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
        // Pull-to-refresh arms on the drag and fires on the release
        // (UIRefreshControl.swift owns the rule and says what is measured).
        _refreshControl?._scrollDidEndDrag()
        let lo = minContentOffset, hi = maxContentOffset
        var off = contentOffset
        var v = v

        // M13: scrollViewWillEndDragging. UIKit's velocity here is in
        // POINTS PER MILLISECOND (the one delegate callback that is not in
        // pt/s — a documented UIKit quirk), and the target it shows is the
        // natural landing offset clamped into range.
        if let d = delegate {
            var target = CGPoint(
                x: Swift.min(Swift.max(UIScrollPhysics.decelTargetOffset(x0: off.x, v0: v.x),
                                       lo.x), hi.x),
                y: Swift.min(Swift.max(UIScrollPhysics.decelTargetOffset(x0: off.y, v0: v.y),
                                       lo.y), hi.y))
            let natural = target
            withUnsafeMutablePointer(to: &target) {
                d.scrollViewWillEndDragging(self, withVelocity: CGPoint(x: v.x / 1000,
                                                                        y: v.y / 1000),
                                            targetContentOffset: $0)
            }
            if target != natural {
                // Land exactly where the delegate asked by solving UIKit's
                // own closed-form deceleration for the release velocity:
                //   target = x0 + (v0 ∓ stop)·F   ->   v0 = (target − x0)/F ± stop
                // The curve is therefore still UIKit's; only its initial
                // velocity is retargeted. UIKit instead reshapes the curve's
                // duration — the landing point matches, the timing does not
                // (docs/KNOWN_GAPS.md).
                v = CGPoint(x: UIScrollPhysics.velocityToLand(from: off.x, at: target.x),
                            y: UIScrollPhysics.velocityToLand(from: off.y, at: target.y))
                // A retarget to the current offset means "stop here".
                if v.x == 0 { off.x = target.x }
                if v.y == 0 { off.y = target.y }
                contentOffset = off
            }
        }

        xAnim = makeReleaseAxisAnim(x: off.x, v: v.x, lo: lo.x, hi: hi.x,
                                    scrolls: dragsX, bouncesAxis: bouncesX, at: now)
        yAnim = makeReleaseAxisAnim(x: off.y, v: v.y, lo: lo.y, hi: hi.y,
                                    scrolls: dragsY, bouncesAxis: bouncesY, at: now)

        let decelerates = xAnim != nil || yAnim != nil
        delegate?.scrollViewDidEndDragging(self, willDecelerate: decelerates)
        _scrollObserver?.scrollViewDidEndDragging(self, willDecelerate: decelerates)
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
            _scrollObserver?.scrollViewDidEndDecelerating(self)
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
        bar.backgroundColor = indicatorColor()
        bar.alpha = 0
        addSubview(bar)
        return bar
    }

    private func indicatorColor() -> UIColor {
        let light: Bool
        switch indicatorStyle {
        case .default: light = traitCollection.userInterfaceStyle == .dark
        case .white: light = true
        case .black: light = false
        }
        return light
            ? UIColor(red: 1, green: 1, blue: 1, alpha: 0.35)
            : UIColor(red: 0, green: 0, blue: 0, alpha: 0.35)
    }

    /// UIKit's public momentary reveal (ios-oss RewardsCollectionViewController
    /// calls it after a reload). It exposes no readable state, so this
    /// reuses the settle-time show/fade pair: bars appear only for a
    /// scrollable axis and fade over `indicatorFadeDuration`. The hold time
    /// before UIKit's fade is not measured; nothing observable depends on it.
    public func flashScrollIndicators() {
        flashIndicators()
        fadeIndicators()
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
            let trackTop = inset + verticalScrollIndicatorInsets.top
            let trackBottom = inset + verticalScrollIndicatorInsets.bottom
            let track = bounds.height - trackTop - trackBottom
            if range > 0, contentLen > 0, track > 0 {
                var len = max(UIScrollView.indicatorMinLength,
                              track * min(1, bounds.height / contentLen))
                // Overscroll: the bar compresses by the overshoot, pinned to
                // its end of the track (UIKit behavior).
                let overshoot = off.y < lo.y ? lo.y - off.y
                              : off.y > hi.y ? off.y - hi.y : 0
                len = max(thick * 2, len - overshoot)
                let p = min(1, max(0, (off.y - lo.y) / range))
                let y = trackTop + (track - len) * p
                bar.frame = CGRect(
                    x: off.x + bounds.width - inset
                        - verticalScrollIndicatorInsets.right - thick,
                                   y: off.y + y, width: thick, height: len)
                bar.isHidden = false
            } else {
                bar.isHidden = true
            }
        }
        if let bar = horizontalIndicator {
            let range = hi.x - lo.x
            let contentLen = contentSize.width + contentInset.left + contentInset.right
            let trackLeading = inset + horizontalScrollIndicatorInsets.left
            let trackTrailing = inset + horizontalScrollIndicatorInsets.right
            let track = bounds.width - trackLeading - trackTrailing
            if range > 0, contentLen > 0, track > 0 {
                var len = max(UIScrollView.indicatorMinLength,
                              track * min(1, bounds.width / contentLen))
                let overshoot = off.x < lo.x ? lo.x - off.x
                              : off.x > hi.x ? off.x - hi.x : 0
                len = max(thick * 2, len - overshoot)
                let p = min(1, max(0, (off.x - lo.x) / range))
                let x = trackLeading + (track - len) * p
                bar.frame = CGRect(x: off.x + x,
                                   y: off.y + bounds.height - inset
                                    - horizontalScrollIndicatorInsets.bottom - thick,
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
@preconcurrency @MainActor
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

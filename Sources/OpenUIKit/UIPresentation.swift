// Modal presentation. Owner: viewcontroller module (M10 chrome, M11 gestures).
//
// The INTERACTIVE behaviour (drag-to-dismiss, grabber, dim interpolation) is
// MEASURED against real iOS 26.1 UIKit, not guessed: Tools/oracle2/sheetprobe
// drives a live UISheetPresentationController in the iOS Simulator with
// synthetic UITouch drags and samples the sheet frame and the dim view's
// presentation opacity per display-link frame
// (scripts/sheet_probe_sim.sh; results in docs/APP_FEEL.md "Measured sheet
// interaction"). The constants live in `UISheetPhysics` below.
//
// UIViewController.present(_:animated:) / dismiss(animated:) with the iOS 26
// pageSheet look, measured from golden/modal_sheet (real iOS 26, iPhone 16
// simulator — Catalyst cannot render the iOS sheet chrome):
//   - Dimming: black at 20% over the presenting content (white base →
//     #CCCCCC). Touches on the dim do nothing (minimal isModalInPresentation
//     semantics — there is no tap-to-dismiss).
//   - Sheet: full width, top edge 59 pt below the window top (MEASURED —
//     sheetprobe reads the live frame as (0, 59, 393, 793); the earlier 59.5
//     was a fit to the golden's edge profile and scored 0.09 pt worse),
//     rounded corners fit from the golden's edge profile (top R ≈ 37.7, bottom
//     R ≈ 58.2 pt — iOS draws continuous corners; a circular fit matches
//     the measured profile within ~0.4 pt on top, ~1.7 pt on the bottom's
//     display-concentric curve).
//   - Present: sheet slides up from below over 0.4 s on a critically damped
//     spring while the dim fades in (feel-matched; scripted captures via
//     the shared animation clock). Dismiss is the exact reverse.
//
// Appearance callbacks follow UIKit: the PRESENTED controller gets
// viewWillAppear/viewDidAppear ("did" fires when the host clock passes the
// transition end — UIView.animate completion, same pattern as navigation
// transitions). The PRESENTING controller only gets disappearance callbacks
// for .fullScreen (a pageSheet leaves it visible, like UIKit).
//
// The presentation attaches to the presenting controller's topmost view
// (its window when it is in one) so the sheet covers navigation bars, tab
// bars and any other chrome.

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


public enum UIModalPresentationStyle {
    /// Resolves to .pageSheet (the iOS default for a plain present).
    case automatic
    case pageSheet
    case fullScreen
    /// UIAlertController's own style: a centred card over a dim, never a
    /// sheet. Set by `UIAlertController.init` — apps do not choose it.
    case alert
    /// M13. On an iPhone-width screen real UIKit ADAPTS a popover instead of
    /// drawing one, and so does this — `.popover` resolves through
    /// `UIPopoverPresentationController.adaptedStyle` (default `.pageSheet`).
    /// See UIAdaptivePresentation.swift.
    case popover
    /// M14. On an iPhone-width screen real UIKit resolves `.formSheet` to the
    /// same sheet presentation as `.pageSheet` (MEASURED — Tools/oracle2/
    /// detentprobe presents a `.formSheet` on a 393 pt window and gets the
    /// pageSheet frame [0, 59, 393, 793] for `.large()`). Apps that want a
    /// self-sizing sheet write `.formSheet` + detents, which is why this case
    /// has to exist for their source to compile.
    case formSheet
}

/// Container for one modal presentation: dimming + sheet, sized to the
/// presentation root. Class name is private to compare.py (never part of
/// scene dumps anyway — layout dumps run before presentation).
@MainActor
final class UIPresentationContainerView: UIView {}

/// The dim behind a sheet: swallows every touch (tap-to-dismiss is NOT the
/// default; minimal isModalInPresentation semantics).
@MainActor
final class _UIDimmingView: UIView {
    /// MEASURED: real iOS 26.1 installs a `UIDimmingView` with
    /// backgroundColor black at exactly alpha 0.2 behind a pageSheet.
    static let maxAlpha: CGFloat = 0.2
}

// MARK: - Sheet interaction physics (MEASURED, iOS 26.1 / iPhone 16)

/// Constants for the interactive pageSheet, every one of them measured from
/// real UIKit by `Tools/oracle2/sheetprobe` (see the file header and
/// docs/APP_FEEL.md "Measured sheet interaction").
public enum UISheetPhysics {
    /// Pan slop absorbed at recognition. MEASURED: the sheet's offset is the
    /// finger's travel MINUS EXACTLY 10 pt at every distance probed
    /// (180/240/320/360/380 pt of travel → 170/230/310/350/370 pt of sheet),
    /// the same rule UIScrollView's pan follows.
    public static let panSlop: CGFloat = 10

    /// Release past this FRACTION of the sheet's height dismisses.
    /// MEASURED = 0.5: on a 793 pt sheet, releasing at rest from 370 pt
    /// springs back and from 398/402 pt dismisses (50 % = 396.5). The rule is
    /// PROPORTIONAL, not a fixed distance — a 400 pt custom detent springs
    /// back from 170 pt and dismisses from 210 pt.
    public static let dismissProgressThreshold: CGFloat = 0.5

    /// ...or release with at least this downward velocity (pt/s), whatever
    /// the distance. MEASURED = 1000 exactly: at 64 pt of travel, releasing
    /// at 975 pt/s springs back and 1000 pt/s dismisses.
    public static let dismissVelocityThreshold: CGFloat = 1000

    /// Both the spring-back and the completing dismissal animate the sheet's
    /// offset with ONE critically damped spring seeded by the release
    /// velocity. MEASURED ω = √(1000/3) = 18.2574 rad/s (mass 3, stiffness
    /// 1000): free fits of three independent releases give 18.251 / 18.256 /
    /// 18.258 with an rms error of 0.02–0.05 pt over the whole curve.
    public static let settleOmega: Double = 18.257418583505537

    /// Trailing window for the release velocity. NOT separately measured for
    /// sheets (the probe's drags run at constant velocity, so every estimator
    /// agrees); inherited from UIScrollView's measured 100 ms window.
    public static let velocityWindow: Double = 0.1

    /// Displacement from the target at time `t` for a critically damped
    /// spring released at displacement `x0` with velocity `v0`.
    public static func displacement(x0: CGFloat, v0: CGFloat, at t: Double) -> CGFloat {
        guard t > 0 else { return x0 }
        let w = settleOmega
        let b = Double(v0) + w * Double(x0)
        return CGFloat((Double(x0) + b * t) * _scrollExp(-w * t))
    }

    /// d/dt of `displacement`.
    public static func velocity(x0: CGFloat, v0: CGFloat, at t: Double) -> CGFloat {
        guard t > 0 else { return v0 }
        let w = settleOmega
        let b = Double(v0) + w * Double(x0)
        return CGFloat((b - w * (Double(x0) + b * t)) * _scrollExp(-w * t))
    }

    /// Settle tolerances (below both, the spring snaps to its target).
    static let settleDisplacement: CGFloat = 0.25
    static let settleVelocity: CGFloat = 2
}

/// The small rounded handle at the top of a sheet. Hidden unless the app sets
/// `sheetPresentationController?.prefersGrabberVisible` — UIKit's default is
/// false, which is why golden/modal_sheet carries no grabber and
/// golden/modal_sheet_grabber does.
///
/// Geometry MEASURED twice and in agreement: the live view hierarchy reports
/// `_UIGrabber [178.5, 64.0, 36.0, 5.0] cornerRadius 2.5` on a 393 pt window
/// whose sheet starts at y 59, and the rendered golden's ink spans exactly
/// x 178.5…214.5, y 64.0…69.0 with a half-pixel antialias fringe.
@MainActor
public final class _UISheetGrabber: UIView {
    public static let width: CGFloat = 36
    public static let height: CGFloat = 5
    /// Gap between the sheet's top edge and the grabber's top edge.
    public static let topInset: CGFloat = 5

    /// MEASURED in light mode: over the white sheet the grabber renders
    /// (197, 197, 200), which is UIKit's systemFill base gray
    /// (0.4706, 0.4706, 0.502) at alpha 0.4295 — solved per channel, and the
    /// blue channel independently confirms it (predicted 200.4, measured
    /// 200.0). Real UIKit draws it as a luma-tracking UIVisualEffectView;
    /// this is the flat equivalent over an opaque background.
    ///
    /// Dark is NOT measured — `drawHierarchy` renders the dark grabber as
    /// nothing at all (the same private-material capture limitation that
    /// blocks the dark textfield border and the dark tab bar, see
    /// docs/KNOWN_GAPS.md). The dark alpha extrapolates the light:dark ratio
    /// UIKit uses for the systemFill family itself (0.2 → 0.36, i.e. ×1.8).
    static let fill = UIColor(dynamicProvider: { traits in
        let a: CGFloat = traits.userInterfaceStyle == .dark ? 0.7731 : 0.4295
        return UIColor(red: 0.4706, green: 0.4706, blue: 0.502, alpha: a)
    })

    public override init(frame: CGRect = .zero) {
        super.init(frame: frame)
        isUserInteractionEnabled = false
        backgroundColor = _UISheetGrabber.fill
        layer.cornerRadius = _UISheetGrabber.height / 2
    }
}

/// The slice of UIKit's `UISheetPresentationController` that OpenUIKit
/// implements. Reachable exactly where UIKit puts it
/// (`vc.sheetPresentationController`) so app code reads the same, but the
/// detent surface is deliberately absent rather than faked — see
/// docs/KNOWN_GAPS.md for the measured detent design that was deferred.
///
/// M12: it is now a real `UIPresentationController` — it OWNS the dimming
/// view and the sheet platter and installs/removes them from the four
/// transition callbacks, instead of `present(_:animated:)` building them
/// inline. The geometry, colours and interaction are byte-for-byte the M11
/// ones (same measured constants, same `installInteraction` call), so every
/// sheet scene, capture and test is unchanged.
@MainActor
public final class UISheetPresentationController: UIPresentationController {
    /// Show the grabber. UIKit's default is `false`.
    public var prefersGrabberVisible: Bool = false {
        didSet { installGrabberIfNeeded() }
    }

    /// pageSheet (dimmed, inset, interactive) or fullScreen (no dim, full
    /// bounds). Set by `present` from the presented controller's resolved
    /// style; the same object serves both, exactly as the M11 inline code
    /// branched on `style`.
    var sheetStyle: UIModalPresentationStyle = .pageSheet

    let dim = _UIDimmingView()
    let platter = _UIPageSheetView()
    /// The presented view's own background, taken over by the platter so the
    /// rounded corners survive; restored on dismissal.
    var savedBackgroundColor: UIColor?

    public override var presentedView: UIView? { platter }

    // MARK: Detents (M14 — see the DIVERGENCE note below)
    //
    // Real UIKit sizes a sheet from `detents`. `.custom { ctx in … }` is how
    // a self-sizing sheet (pocket-casts' options picker, docs/REAL_APP_TEST.md)
    // asks to be exactly as tall as its content.
    //
    // MEASURED on real iOS 26 by Tools/oracle2/detentprobe
    // (scripts/detent_probe_sim.sh, 13 cases, JSON committed under
    // fixtures/realapp/):
    //
    //   * container 393x852, window safe area top 59 / bottom 34
    //   * `context.maximumDetentValue` == 759 == 852 - 59 - 34, i.e.
    //     containerHeight - the sheet's top inset - the bottom safe area.
    //     THIS IS EXACT and is what the code below computes.
    //   * `.large()` sits at [0, 59, 393, 793] — identical to the sheet
    //     OpenUIKit already drew, so the large case is unchanged and stays
    //     golden-clean.
    //   * a custom value ABOVE the maximum collapses to exactly the `.large`
    //     frame. Reproduced.
    //   * a custom value BELOW the maximum puts the sheet's content `value`
    //     points tall with the bottom safe area added underneath, which is
    //     what the code below does.
    //
    // DIVERGENCE, stated because it is visible: on iOS 26 a non-large detent
    // is drawn as a FLOATING card — inset 8 pt on each side, 8 pt off the
    // bottom, and scaled by 377/393 — not as an edge-to-edge sheet. The probe
    // captures that (e.g. detent 400 -> [8, 427.669, 377, 416.331]) and the
    // numbers do not decompose into an inset plus a height without also
    // modelling the transform. OpenUIKit draws the edge-to-edge sheet at the
    // right HEIGHT instead. Closing this needs the floating-card geometry
    // measured properly; the probe that would do it is committed.
    public var detents: [Detent] = [.large()]
    public var selectedDetentIdentifier: Detent.Identifier?

    public struct Detent {
        public struct Identifier: Hashable, RawRepresentable, Sendable {
            public let rawValue: String
            public init(rawValue: String) { self.rawValue = rawValue }
            public static let medium = Identifier(rawValue: "com.apple.UIKit.medium")
            public static let large = Identifier(rawValue: "com.apple.UIKit.large")
        }

        /// What UIKit hands a `.custom` resolver.
        public struct ResolutionContext {
            public let maximumDetentValue: CGFloat
            public let containerTraitCollection: UITraitCollection
        }

        public let identifier: Identifier
        let resolve: (ResolutionContext) -> CGFloat?

        public static func large() -> Detent {
            Detent(identifier: .large, resolve: { $0.maximumDetentValue })
        }
        /// Measured: the medium sheet's content is 425 pt on an 852 pt
        /// container -- half the container height to within a point. The
        /// container height is not on the resolution context, so the actual
        /// number is computed in `resolvedDetentHeight()`; this resolver is
        /// never consulted for `.medium`.
        public static func medium() -> Detent {
            Detent(identifier: .medium, resolve: { _ in nil })
        }
        public static func custom(identifier: Identifier? = nil,
                                  resolver: @escaping (ResolutionContext) -> CGFloat?) -> Detent {
            Detent(identifier: identifier ?? Identifier(rawValue: "custom"),
                   resolve: resolver)
        }
    }

    /// `containerHeight - topInset - bottomSafeArea` (measured: 759 on a
    /// 393x852 iPhone container).
    var maximumDetentValue: CGFloat {
        guard let c = containerView else { return 0 }
        return max(0, c.bounds.height - _UIPageSheetView.topInset
                      - c.safeAreaInsets.bottom)
    }

    /// The height the selected detent asks for, or nil when the sheet should
    /// take the full (large) frame.
    func resolvedDetentHeight() -> CGFloat? {
        guard let c = containerView, !detents.isEmpty else { return nil }
        let detent = detents.first { $0.identifier == selectedDetentIdentifier }
            ?? detents[0]
        if detent.identifier == .medium {
            // Measured 425 on an 852 pt container = half its height, to
            // within a point.
            return c.bounds.height / 2 + c.safeAreaInsets.bottom
        }
        let ctx = Detent.ResolutionContext(
            maximumDetentValue: maximumDetentValue,
            containerTraitCollection: c.traitCollection)
        guard let v = detent.resolve(ctx) else { return nil }
        // Above the maximum UIKit collapses to the large frame (measured).
        guard v < maximumDetentValue else { return nil }
        return max(0, v) + c.safeAreaInsets.bottom
    }

    public override var frameOfPresentedViewInContainerView: CGRect {
        guard let c = containerView else { return .zero }
        guard sheetStyle == .pageSheet else { return c.bounds }
        if let h = resolvedDetentHeight() {
            return CGRect(x: 0, y: c.bounds.height - h,
                          width: c.bounds.width, height: h)
        }
        return CGRect(x: 0, y: _UIPageSheetView.topInset,
                      width: c.bounds.width,
                      height: c.bounds.height - _UIPageSheetView.topInset)
    }

    /// Only a fullScreen presentation covers the presenter (UIKit: a
    /// pageSheet leaves it on screen, so it gets no disappearance calls).
    public override var shouldRemovePresentersView: Bool { sheetStyle == .fullScreen }

    public override func presentationTransitionWillBegin() {
        guard let container = containerView else { return }
        let vc = presentedViewController
        dim.frame = container.bounds
        dim.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        dim.backgroundColor = .black
        // The FINAL (presented) chrome state. A non-animated present needs
        // nothing else; the animator winds it back to the start and plays
        // forward.
        dim.alpha = _UIDimmingView.maxAlpha
        if sheetStyle == .pageSheet { container.addSubview(dim) }

        platter.frame = frameOfPresentedViewInContainerView
        platter.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        vc.loadViewIfNeeded()
        let cv = vc.view!
        savedBackgroundColor = cv.backgroundColor
        if sheetStyle == .pageSheet {
            if let bg = cv.backgroundColor { platter.fillColor = bg }
            cv.backgroundColor = nil
        } else if cv.backgroundColor == nil {
            platter.fillColor = .systemBackground
        }
        cv.frame = platter.bounds
        cv.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        platter.addSubview(cv)
        if sheetStyle == .pageSheet {
            platter.restY = platter.frame.minY
            platter.installInteraction(presented: vc, dim: dim)
        }
        container.addSubview(platter)
        // AFTER the platter is in the hierarchy: `installGrabberIfNeeded`
        // refuses to run on a detached platter (app code usually sets
        // `prefersGrabberVisible` before presenting, when there is no platter
        // frame yet), so this is the call that actually installs it.
        installGrabberIfNeeded()
    }

    public override func dismissalTransitionWillBegin() {
        // A programmatic dismiss during an interactive one takes over: drop
        // the release spring and animate from wherever the finger left it.
        platter.settle = nil
    }

    public override func dismissalTransitionDidEnd(_ completed: Bool) {
        guard completed else { return }
        presentedViewController.viewIfLoaded?.backgroundColor = savedBackgroundColor
        presentedViewController.viewIfLoaded?.removeFromSuperview()
        containerView?.removeFromSuperview()
    }

    /// Add (or remove) the grabber to match `prefersGrabberVisible`.
    func installGrabberIfNeeded() {
        guard sheetStyle == .pageSheet, platter.superview != nil else { return }
        let existing = platter.subviews.compactMap { $0 as? _UISheetGrabber }.first
        if !prefersGrabberVisible {
            existing?.removeFromSuperview()
            return
        }
        let grabber = existing ?? _UISheetGrabber()
        // Centred WITHOUT rounding: on a 393 pt sheet real UIKit reports
        // x = 178.5, i.e. it keeps the half point.
        grabber.frame = CGRect(
            x: (platter.bounds.width - _UISheetGrabber.width) / 2,
            y: _UISheetGrabber.topInset,
            width: _UISheetGrabber.width, height: _UISheetGrabber.height)
        grabber.autoresizingMask = [.flexibleLeftMargin, .flexibleRightMargin]
        if existing == nil { platter.addSubview(grabber) }
    }
}

/// The built-in modal animator: the sheet slides up from below the container
/// while the dim fades in; dismissal is the exact reverse. This is the M11
/// code, moved behind `UIViewControllerAnimatedTransitioning` so an app's
/// `transitioningDelegate` can replace it (docs/APP_COMPAT.md "Custom
/// transitions").
@MainActor
final class _UIPageSheetAnimator: UIViewControllerAnimatedTransitioning {
    let presenting: Bool
    init(presenting: Bool) { self.presenting = presenting }

    func transitionDuration(using _: UIViewControllerContextTransitioning?) -> TimeInterval {
        UIViewController.presentTransitionDuration
    }

    func animateTransition(using ctx: UIViewControllerContextTransitioning) {
        let container = ctx.containerView
        guard let moving = ctx.view(forKey: presenting ? .to : .from) else {
            ctx.completeTransition(true)
            return
        }
        let dim = (moving.superview?.subviews.first { $0 is _UIDimmingView })
        let duration = transitionDuration(using: ctx)
        if presenting {
            let up = moving.frame
            moving.frame = up.offsetBy(dx: 0, dy: container.bounds.height - up.minY)
            let dimTarget = dim?.alpha ?? 0
            dim?.alpha = 0
            UIView.animate(withDuration: duration, delay: 0, usingSpringWithDamping: 1,
                           initialSpringVelocity: 0, options: [], animations: {
                moving.frame = up
                dim?.alpha = dimTarget
            }, completion: { _ in ctx.completeTransition(true) })
        } else {
            UIView.animate(withDuration: duration, delay: 0, usingSpringWithDamping: 1,
                           initialSpringVelocity: 0, options: [], animations: {
                moving.frame = moving.frame.offsetBy(
                    dx: 0, dy: container.bounds.height - moving.frame.minY)
                dim?.alpha = 0
            }, completion: { _ in ctx.completeTransition(true) })
        }
    }
}

/// The sheet platter: fills its bounds with the measured rounded-corner
/// shape. The presented view sits on top with a clear background — the
/// platter provides the background color so the corners stay rounded.
@MainActor
final class _UIPageSheetView: UIView {
    static let topInset: CGFloat = 59.0
    static let topCornerRadius: CGFloat = 37.7
    static let bottomCornerRadius: CGFloat = 58.2

    /// Sheet background; defaults to systemBackground, resolved at draw
    /// time against the effective traits.
    var fillColor: UIColor = .systemBackground {
        didSet { setNeedsDisplay() }
    }

    // MARK: Interactive dismissal state

    /// The presented controller this sheet is showing (for the teardown when
    /// an interactive dismissal completes).
    weak var presented: UIViewController?
    weak var dim: _UIDimmingView?
    /// frame.minY with the sheet fully presented.
    var restY: CGFloat = 0
    /// How far the sheet is currently dragged DOWN from `restY` (never
    /// negative — MEASURED: real iOS does not move a sheet above its detent).
    var dragOffset: CGFloat = 0
    var pan: _UISheetPanGestureRecognizer?

    /// Trailing (t, offset) samples for the release velocity.
    var dragSamples: [(t: TimeInterval, offset: CGFloat)] = []
    /// Offset at the moment the drag began (non-zero when the finger catches
    /// a settling sheet).
    var dragStartOffset: CGFloat = 0

    /// In-flight release spring: displacement `x0` from `target` at `start`.
    struct Settle {
        var start: TimeInterval
        var x0: CGFloat
        var v0: CGFloat
        var target: CGFloat
        /// The sheet is on its way out; tear the presentation down on settle.
        var dismisses: Bool
    }
    var settle: Settle?

    override init(frame: CGRect = .zero) {
        super.init(frame: frame)
        isOpaque = false
        clipsToBounds = false
    }

    override func drawContent(in canvas: Canvas, bounds: CGRect) {
        let path = _UIPageSheetView.sheetPath(
            in: bounds,
            topRadius: _UIPageSheetView.topCornerRadius,
            bottomRadius: _UIPageSheetView.bottomCornerRadius)
        let color = fillColor.resolvedColor(with: traitCollection).cgColor
        canvas.fill(path, color: color)
    }

    /// Rounded rect with independent top/bottom corner radii (circular
    /// arcs via the standard cubic approximation).
    static func sheetPath(in r: CGRect, topRadius: CGFloat,
                          bottomRadius: CGFloat) -> Path {
        let k: CGFloat = 0.5522847498
        let rt = min(topRadius, min(r.width, r.height) / 2)
        let rb = min(bottomRadius, min(r.width, r.height) / 2)
        var p = Path()
        p.move(to: CGPoint(x: r.minX + rt, y: r.minY))
        p.addLine(to: CGPoint(x: r.maxX - rt, y: r.minY))
        p.addCurve(to: CGPoint(x: r.maxX, y: r.minY + rt),
                   control1: CGPoint(x: r.maxX - rt + k * rt, y: r.minY),
                   control2: CGPoint(x: r.maxX, y: r.minY + rt - k * rt))
        p.addLine(to: CGPoint(x: r.maxX, y: r.maxY - rb))
        p.addCurve(to: CGPoint(x: r.maxX - rb, y: r.maxY),
                   control1: CGPoint(x: r.maxX, y: r.maxY - rb + k * rb),
                   control2: CGPoint(x: r.maxX - rb + k * rb, y: r.maxY))
        p.addLine(to: CGPoint(x: r.minX + rb, y: r.maxY))
        p.addCurve(to: CGPoint(x: r.minX, y: r.maxY - rb),
                   control1: CGPoint(x: r.minX + rb - k * rb, y: r.maxY),
                   control2: CGPoint(x: r.minX, y: r.maxY - rb + k * rb))
        p.addLine(to: CGPoint(x: r.minX, y: r.minY + rt))
        p.addCurve(to: CGPoint(x: r.minX + rt, y: r.minY),
                   control1: CGPoint(x: r.minX, y: r.minY + rt - k * rt),
                   control2: CGPoint(x: r.minX + rt - k * rt, y: r.minY))
        p.close()
        return p
    }

    // MARK: Drag to dismiss

    /// Install the pan once the sheet is in the hierarchy.
    func installInteraction(presented vc: UIViewController, dim: _UIDimmingView?) {
        self.presented = vc
        self.dim = dim
        restY = frame.minY
        guard pan == nil else { return }
        let p = _UISheetPanGestureRecognizer()
        p.sheet = self
        p.addTarget { [weak self] r in
            guard let self, let r = r as? _UISheetPanGestureRecognizer else { return }
            self.handlePan(r)
        }
        pan = p
        addGestureRecognizer(p)
    }

    /// Move the sheet to `offset` points below its rest position and
    /// interpolate the dim with it.
    ///
    /// MEASURED: the dimming alpha is exactly LINEAR in drag progress —
    /// alpha = 0.2 · (1 − offset / sheetHeight). Over four full drags the
    /// residual against that model never exceeds 0.0025 (display-link
    /// sampling lag), so this is the real relationship, not an approximation.
    func applyDragOffset(_ offset: CGFloat) {
        let h = bounds.height
        let o = min(max(offset, 0), h)
        dragOffset = o
        frame.origin.y = restY + o
        let progress = h > 0 ? o / h : 0
        dim?.alpha = _UIDimmingView.maxAlpha * (1 - progress)
    }

    func handlePan(_ pan: _UISheetPanGestureRecognizer) {
        switch pan.state {
        case .began:
            settle = nil
            dragStartOffset = dragOffset
            // The finger takes ownership of the sheet's frame and the dim's
            // alpha. Both may still carry the present/dismiss UIView.animate,
            // and a recorded animation pins the PRESENTATION to its `to`
            // value even after it has ended (see
            // UIView._removeFinishedAnimations) — leaving them in place makes
            // the drag move the model while the screen stays put.
            removeAllAnimations()
            dim?.removeAllAnimations()
            // Absorb EXACTLY the 10 pt activation slop, the same way (and for
            // the same measured reason) as UIScrollView's pan.
            let tr = pan.translation(in: nil)
            let mag = (tr.x * tr.x + tr.y * tr.y).squareRoot()
            if mag > pan.activationDistance {
                let s = (mag - pan.activationDistance) / mag
                pan.setTranslation(CGPoint(x: tr.x * s, y: tr.y * s), in: nil)
            } else {
                pan.setTranslation(.zero, in: nil)
            }
            dragSamples = []
            fallthrough
        case .changed:
            applyDragOffset(dragStartOffset + pan.translation(in: nil).y)
            recordDragSample(t: pan.lastTimestamp, offset: dragOffset)
        case .ended, .cancelled:
            recordDragSample(t: pan.lastTimestamp, offset: dragOffset)
            let v = pan.state == .cancelled ? 0 : releaseVelocity()
            let tEnd = pan.trackedTouches.map(\.timestamp).max() ?? pan.lastTimestamp
            endDrag(velocity: v, at: tEnd)
        default:
            break
        }
    }

    func recordDragSample(t: TimeInterval, offset: CGFloat) {
        dragSamples.append((t, offset))
        let cutoff = t - UISheetPhysics.velocityWindow - 0.02
        while dragSamples.count > 2, dragSamples[0].t < cutoff {
            dragSamples.removeFirst()
        }
    }

    /// Offset velocity (pt/s) over the trailing window.
    func releaseVelocity() -> CGFloat {
        guard let first = dragSamples.first, let last = dragSamples.last else { return 0 }
        let dt = last.t - first.t
        guard dt > 0 else { return 0 }
        return (last.offset - first.offset) / CGFloat(dt)
    }

    /// Decide dismiss vs. spring-back and start the settle spring.
    func endDrag(velocity: CGFloat, at time: TimeInterval) {
        let h = bounds.height
        let progress = h > 0 ? dragOffset / h : 0
        // MEASURED: dismiss past 50 % of the sheet's height OR at ≥ 1000 pt/s
        // downward. A firm UPWARD fling always cancels (not separately
        // measured; mirrors the interactive-pop rule).
        var dismisses: Bool
        if velocity >= UISheetPhysics.dismissVelocityThreshold {
            dismisses = true
        } else if velocity <= -UISheetPhysics.dismissVelocityThreshold {
            dismisses = false
        } else {
            dismisses = progress > UISheetPhysics.dismissProgressThreshold
        }
        // UIKit: a controller that refuses dismissal always springs back —
        // either through isModalInPresentation or through the presentation
        // controller's delegate (M13). A refused attempt is reported.
        let pc = presented?._presentationController
        let delegateRefuses = pc.map { c in
            !(c.delegate?.presentationControllerShouldDismiss(c) ?? true)
        } ?? false
        if dismisses, presented?.isModalInPresentation == true || delegateRefuses {
            dismisses = false
            if let pc { pc.delegate?.presentationControllerDidAttemptToDismiss(pc) }
        }
        if dismisses, let pc { pc.delegate?.presentationControllerWillDismiss(pc) }
        let target: CGFloat = dismisses ? h : 0
        guard dragOffset != target || velocity != 0 else {
            if dismisses { finishInteractiveDismiss() }
            return
        }
        settle = Settle(start: time, x0: dragOffset - target, v0: velocity,
                        target: target, dismisses: dismisses)
        _UIPageSheetView.registerSettling(self)
    }

    /// Advance the release spring to the host clock.
    func stepSettle(to time: TimeInterval) {
        guard let s = settle else { return }
        let dt = time - s.start
        let d = UISheetPhysics.displacement(x0: s.x0, v0: s.v0, at: dt)
        let v = UISheetPhysics.velocity(x0: s.x0, v0: s.v0, at: dt)
        if d.magnitude < UISheetPhysics.settleDisplacement,
           v.magnitude < UISheetPhysics.settleVelocity {
            settle = nil
            applyDragOffset(s.target)
            if s.dismisses { finishInteractiveDismiss() }
            return
        }
        applyDragOffset(s.target + d)
    }

    /// The sheet has flown off the bottom: run the same teardown a
    /// programmatic dismiss would.
    func finishInteractiveDismiss() {
        guard let vc = presented, let presenter = vc.presentingViewController else { return }
        presented = nil
        let pc = vc._presentationController
        presenter._tearDownPresentation(of: vc, completion: nil)
        // UIKit reports didDismiss for USER-driven dismissals only, which is
        // why it lives here and not in _tearDownPresentation (M13).
        if let pc { pc.delegate?.presentationControllerDidDismiss(pc) }
    }

    // MARK: Settle registry (host clock stepping)

    private struct WeakSheet { weak var sheet: _UIPageSheetView? }
    private static var settling: [WeakSheet] = []

    static func registerSettling(_ sheet: _UIPageSheetView) {
        settling.removeAll { $0.sheet == nil }
        if !settling.contains(where: { $0.sheet === sheet }) {
            settling.append(WeakSheet(sheet: sheet))
        }
    }

    /// Advance every settling sheet to `time`. UIWindow.tick calls this, the
    /// same pattern as UIScrollView._stepScrollAnimations.
    static func _stepSheetInteractions(to time: TimeInterval) {
        guard !settling.isEmpty else { return }
        for entry in settling { entry.sheet?.stepSettle(to: time) }
        settling.removeAll { $0.sheet == nil || $0.sheet!.settle == nil }
    }

    /// A sheet release spring is still running (host redraw hint).
    static var _hasActiveSheetInteraction: Bool {
        settling.contains { $0.sheet?.settle != nil }
    }
}

extension UIViewController {
    /// A released sheet drag is still settling — spring-back or completing
    /// dismissal (host redraw hint; the sheet view itself stays internal).
    public static var _hasActiveSheetInteraction: Bool {
        _UIPageSheetView._hasActiveSheetInteraction
    }
}

/// The sheet's pan, with the measured hand-off to a scroll view inside it.
///
/// MEASURED: with a UIScrollView filling the sheet, dragging DOWN while it
/// sits at the top of its content moves the SHEET and leaves contentOffset at
/// 0; dragging up (or down from anywhere else) scrolls the content and leaves
/// the sheet still. The two recognizers gate themselves on exactly that
/// condition from opposite sides — OpenUIKit has no require(toFail:)
/// dependency system (docs/KNOWN_GAPS.md), so the rule is written twice
/// rather than expressed once.
@MainActor
public final class _UISheetPanGestureRecognizer: UIPanGestureRecognizer {
    weak var sheet: _UIPageSheetView?

    public override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
        if _state == .possible {
            let p = location(in: nil)
            let dx = p.x - startLocation.x, dy = p.y - startLocation.y
            if (dx * dx + dy * dy).squareRoot() > activationDistance,
               !allowBegin(dx: dx, dy: dy) {
                state = .failed
            }
        }
        super.touchesMoved(touches, with: event)
    }

    /// The sheet takes the drag only when no scroll view under the finger
    /// wants it: the drag must lead vertically DOWNWARD, and any enclosing
    /// scroll view must already be at the top of its content.
    func allowBegin(dx: CGFloat, dy: CGFloat) -> Bool {
        guard dy > 0, dy.magnitude > dx.magnitude else { return false }
        for t in trackedTouches {
            guard let sv = UIScrollView.enclosingScrollView(of: t.view),
                  sv.dragsY else { continue }
            if sv.contentOffset.y > sv.minContentOffset.y { return false }
        }
        return true
    }
}

extension UIViewController {
    /// Present duration (feel-matched slide-up; critically damped spring).
    public static let presentTransitionDuration: Double = 0.4

    /// The style `modalPresentationStyle` resolves to for this
    /// presentation (.automatic → .pageSheet, the iOS default).
    var _resolvedPresentationStyle: UIModalPresentationStyle {
        switch modalPresentationStyle {
        case .automatic: return .pageSheet
        // Measured: iPhone-width formSheet == pageSheet (file header).
        case .formSheet: return .pageSheet
        case .popover: return _popoverController?.adaptedStyle ?? .pageSheet
        default: return modalPresentationStyle
        }
    }

    // MARK: Present
    //
    // M12: the presentation now runs through UIPresentationController +
    // UIViewControllerAnimatedTransitioning (see
    // UIViewControllerTransitioning.swift). Order:
    //   1. pick the presentation controller (transitioningDelegate's, or the
    //      controller's built-in one)
    //   2. install the container, wire both controllers up
    //   3. presentationTransitionWillBegin  (chrome, in its FINAL state)
    //   4. appearance "will" callbacks
    //   5. animator (transitioningDelegate's, or the built-in) — it winds the
    //      chrome back to the start and plays forward; a non-animated present
    //      skips it entirely, which is why step 3 leaves the final state
    //   6. presentationTransitionDidEnd(true), appearance "did", completion

    public func present(_ vc: UIViewController, animated: Bool,
                        completion: (() -> Void)? = nil) {
        // UIKit forwards a present from a covered controller to the top of
        // the presentation stack.
        if let already = presentedViewController {
            already.present(vc, animated: animated, completion: completion)
            return
        }
        guard vc.presentingViewController == nil else { return }
        loadViewIfNeeded()

        // Presentation root: the topmost ancestor of our view (the window
        // when we are installed in one).
        var root: UIView = view
        while let s = root.superview { root = s }

        let container = UIPresentationContainerView(frame: root.bounds)
        container.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        let pc = vc.transitioningDelegate?.presentationController(
            forPresented: vc, presenting: self, source: self)
            ?? vc._makeDefaultPresentationController(presenting: self)
        pc.presentingViewController = self
        pc.containerView = container
        root.addSubview(container)

        presentedViewController = vc
        vc.presentingViewController = self
        vc._presentationController = pc

        pc.presentationTransitionWillBegin()

        let presenterDisappears = pc.shouldRemovePresentersView
        if presenterDisappears { beginAppearanceTransition(false, animated: animated) }
        vc.beginAppearanceTransition(true, animated: animated)

        let finish = { [weak self, weak vc] in
            pc.presentationTransitionDidEnd(true)
            vc?.endAppearanceTransition()
            if presenterDisappears { self?.endAppearanceTransition() }
            completion?()
        }
        guard animated else { finish(); return }

        let animator = vc.transitioningDelegate?.animationController(
            forPresented: vc, presenting: self, source: self)
            ?? vc._makeDefaultPresentAnimator()
        let ctx = _UIModalTransitionContext(
            containerView: container, animated: true, presenting: true,
            from: self, to: vc, fromView: viewIfLoaded, toView: pc.presentedView,
            startFrame: pc.frameOfPresentedViewInContainerView,
            endFrame: pc.frameOfPresentedViewInContainerView)
        ctx.onComplete = { _ in finish() }
        vc._activeTransitionContext = ctx
        animator.animateTransition(using: ctx)
    }

    // MARK: Dismiss

    public func dismiss(animated: Bool, completion: (() -> Void)? = nil) {
        // UIKit: a dismiss on a controller that presented something
        // dismisses ITS presented controller; a dismiss on a presented
        // controller dismisses itself.
        let vc: UIViewController
        if let presented = presentedViewController {
            // Collapse anything stacked above it first (non-animated), then
            // animate this one down.
            presented.presentedViewController?.dismiss(animated: false)
            vc = presented
        } else if let presenter = presentingViewController {
            presenter.dismiss(animated: animated, completion: completion)
            return
        } else {
            return
        }

        let presenter = self
        guard let pc = vc._presentationController else { return }
        let presenterReappears = pc.shouldRemovePresentersView

        vc.beginAppearanceTransition(false, animated: animated)
        if presenterReappears { presenter.beginAppearanceTransition(true, animated: animated) }
        pc.dismissalTransitionWillBegin()

        let finish = { [weak presenter] in
            presenter?._tearDownPresentation(of: vc, completion: completion)
        }
        guard animated, let moving = pc.presentedView else { finish(); return }

        let animator = vc.transitioningDelegate?.animationController(forDismissed: vc)
            ?? vc._makeDefaultDismissAnimator()
        let ctx = _UIModalTransitionContext(
            containerView: pc.containerView ?? moving,
            animated: true, presenting: false,
            from: vc, to: presenter, fromView: moving, toView: presenter.viewIfLoaded,
            startFrame: moving.frame, endFrame: moving.frame)
        ctx.onComplete = { _ in finish() }
        vc._activeTransitionContext = ctx
        animator.animateTransition(using: ctx)
    }

    /// Remove a presentation's views and reset both controllers. Shared by
    /// the programmatic dismiss and the interactive one (which reaches its
    /// end state through the sheet's own release spring rather than a
    /// UIView.animate completion).
    func _tearDownPresentation(of vc: UIViewController, completion: (() -> Void)?) {
        guard vc.presentingViewController === self else { return }
        let pc = vc._presentationController
        let presenterReappears = pc?.shouldRemovePresentersView ?? false
        // The interactive path never called beginAppearanceTransition — do it
        // now so the will/did pair (and the presentation controller's
        // will/did pair) stays balanced either way.
        if !vc._isDisappearing {
            vc.beginAppearanceTransition(false, animated: true)
            if presenterReappears { beginAppearanceTransition(true, animated: true) }
            pc?.dismissalTransitionWillBegin()
        }
        pc?.dismissalTransitionDidEnd(true)
        vc.endAppearanceTransition()
        if presenterReappears { endAppearanceTransition() }
        vc.presentingViewController = nil
        presentedViewController = nil
        vc._presentationController = nil
        vc._activeTransitionContext = nil
        completion?()
    }

    // MARK: Sheet presentation controller

    /// UIKit's accessor: non-nil exactly when this controller is (or will be)
    /// presented as a sheet.
    public var sheetPresentationController: UISheetPresentationController? {
        guard _resolvedPresentationStyle == .pageSheet else { return nil }
        if let existing = _sheetController { return existing }
        let c = UISheetPresentationController(presentedViewController: self, presenting: nil)
        _sheetController = c
        return c
    }

}

// MARK: - Compatibility accessors for the sheet chrome
//
// The sheet's dim/platter/container moved onto the presentation controller in
// M12; these keep the old names working for the interaction code and tests.
extension UIViewController {
    var _presentationController_sheet: UISheetPresentationController? {
        _presentationController as? UISheetPresentationController
    }
    var _presentationContainer: UIView? { _presentationController?.containerView }
    var _presentationSheet: _UIPageSheetView? { _presentationController_sheet?.platter }
    var _presentationDim: UIView? { _presentationController_sheet?.dim }
}

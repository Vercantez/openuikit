// UIRefreshControl + its UIScrollView pull-to-refresh integration.
// Owner: controls module (app-compat cluster "controls2").
//
// GEOMETRY — ALL MEASURED from real UIKit (Mac Catalyst iOS 26.1) through
// the offscreen oracle, which renders this control faithfully (unlike the
// search bar and the stepper, whose chrome is a private material / a SwiftUI
// hosting view). Probe: a UIRefreshControl attached to a UIScrollView, view
// tree + CALayer tree dumped, then rendered with `layer.render(in:)` and the
// ink measured off the pixels.
//
//   * The control's frame is (0, contentOffset.y, scrollView.width, 60):
//     60 pt tall (`controlHeight`), full width, and its ORIGIN TRACKS the
//     scroll offset — measured over a −0…−200 pt sweep, rc.frame.y == offset
//     at every step. It is `isHidden == true` whenever it is not refreshing.
//   * The spinner is a CAReplicatorLayer with `instanceCount == 8` and an
//     `instanceTransform` of exactly 45 degrees, hosted in a 100x100 box
//     CENTRED in the control (measured (110, −20, 100, 100) in a 320x60
//     control). The seed blade is a 3.5 x 10 pt rounded rect with corner
//     radius 1.75, at (48.5, 35) in that box — i.e. a capsule whose long
//     axis is radial, whose centre sits 10 pt from the graphic centre, and
//     whose ink therefore spans radius 5…15. The rendered PNG confirms it:
//     the ink bounding box is exactly 30 x 30 pt centred on the control.
//   * Blade colour (Catalyst rest pose / frozen SimScene): `label` at
//     alpha 216/255 = 0.847059. All eight blades share it.
//
// iOS 26.1 APPEAR (MEASURED spinnerprobe rc_n0..24 + Feed t700 / Pager
// t4650, iPhone SE 2x, freeze at the first CASpringAnimation.beginTime
// + N/60 — the same clock confprobe uses). Seed pbg is light
// `secondaryLabel` (0.235294, 0.235294, 0.262745, 0.6). Replicator
// opacity is a 1 s CABasicAnimation from 0 whose presentation matches
// easeInOut (0.42, 0, 0.58, 1) (rc_n9 / t=0.15: 0.04521; rc_n18 /
// t=0.30: 0.18740; rms 3e-7). Transform is discrete 45° every 0.125 s
// (keyTimes 0, 0.125, …, 1, duration 1, calculationMode discrete;
// n=9 → 45°, n=18 → 90°). instanceAlphaOffset is a slow overdamped
// spring (mass 1, k 5, c 5000) still ≈ 0.004 / 0.012 at those frames
// — all eight blades read the same faint ink, so it is not drawn.
// Frozen rest (elapsed 0, suite `control_refresh`) keeps the Catalyst
// uniform `label`@216/255 pose.
//
// WHAT IS **NOT** MEASURED, and why
//
//   * instanceAlphaOffset past the first 0.4 s, and instanceColor's
//     spring to-value. Feed t700 / Pager t4650 land at 0.30 / 0.15 s.
//   * The PULL THRESHOLD and the refreshing content inset. Neither is
//     observable offscreen: driving `contentOffset` to −200 pt through the
//     property never fires `.valueChanged` and never sets `isRefreshing`,
//     because UIKit arms the trigger from the real pan gesture's end, which
//     an offscreen scroll view has no way to receive. The numbers used here
//     — trigger at a drag past `controlHeight` (60 pt) beyond the top edge,
//     released; hold `contentInset.top += controlHeight` while refreshing —
//     are UIKit's DOCUMENTED behaviour, not a measurement. Pinning them
//     needs a synthetic drag in the iOS Simulator, the route
//     `Tools/oracle2/scrollprobe.swift` already established for the scroll
//     physics (golden/scroll_traces/SCHEMA.md).
//   * `attributedTitle` is stored and NOT drawn. Real UIKit puts a 12 pt
//     label at (10, 48.5, width−20, 0) under the spinner — height ZERO and
//     alpha 0 with no title, i.e. the fixture cannot see it either.

@preconcurrency @MainActor
open class UIRefreshControl: UIControl {
    /// Measured: the control is always 60 pt tall.
    public static let controlHeight: CGFloat = 60

    /// Measured blade geometry (file header).
    static let bladeCount = 8
    static let bladeLength: CGFloat = 10
    static let bladeThickness: CGFloat = 3.5
    /// Distance from the graphic centre to a blade's centre (vertical).
    static let bladeRing: CGFloat = 10
    /// Horizontal offset of the seed blade's centre from the graphic centre:
    /// the measured seed sits at x 48.5…52 in a 100 pt box, centre 50.25.
    static let bladeSeedDX: CGFloat = 0.25
    /// Measured uniform blade alpha, 216/255 (Catalyst / frozen rest).
    static let bladeAlpha: CGFloat = 216.0 / 255.0
    /// Replicator opacity animation duration (MEASURED spinnerprobe:
    /// CABasicAnimation duration 1, fillMode both).
    static let iOSAppearOpacityDuration: Double = 1.0
    /// Discrete 45° step of the replicator transform (MEASURED keyTimes
    /// 0, 0.125, …, 1 on a 1 s discrete keyframe).
    static let iOSAppearStepDuration: Double = 0.125

    public private(set) var isRefreshing = false

    /// Stored, never drawn — see the file header.
    public var attributedTitle: NSAttributedString?

    /// `OpenUIKitRuntime.animationTime` when `beginRefreshing` started.
    /// Drives the iOS-cut appear (opacity + 45° steps) so a named
    /// conformance frame is deterministic.
    var animationStart: Double = 0

    /// The scroll view this control is installed in.
    weak var _scrollView: UIScrollView?
    /// The scroll view's `contentInset.top` before this control claimed it.
    var _baseTopInset: CGFloat = 0
    /// True while the finger has pulled past the trigger distance, so a
    /// release starts a refresh.
    var _armed = false

    public override init(frame: CGRect) {
        super.init(frame: frame)
        isHidden = true
        isUserInteractionEnabled = false
    }

    public convenience init() {
        self.init(frame: CGRect(x: 0, y: 0, width: 320,
                                height: UIRefreshControl.controlHeight))
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        isHidden = true
        isUserInteractionEnabled = false
    }

    /// True while this control is holding the scroll view's top inset open
    /// so the spinner stays on screen. Only a USER-STARTED refresh does
    /// that — see `beginRefreshing()`.
    var _holdsInset = false

    /// Starts the spinner. It does **not** scroll the view: UIKit documents
    /// that a programmatic `beginRefreshing()` leaves `contentOffset` alone
    /// and the app must scroll to reveal the control itself, and the oracle
    /// agrees (a refreshing control offscreen keeps frame (0, 0, W, 60), i.e.
    /// the untouched offset — golden/control_refresh.layout.json). A refresh
    /// the USER pulled for is different: that path holds the inset open, in
    /// `_scrollDidEndDrag()`.
    ///
    /// iOS 26.1 exception, MEASURED Feed t700, iPhone SE 2x: when the
    /// control is ALREADY revealed (offset below `-adjustedContentInset.top`),
    /// beginRefreshing rebases offset by −60 (the control height) and the
    /// large-title bar stretches 106 → 166. Catalyst and a rest-offset
    /// programmatic start are unchanged.
    public func beginRefreshing() {
        guard !isRefreshing else { return }
        isRefreshing = true
        isHidden = false
        animationStart = OpenUIKitRuntime.animationTime
        if OpenUIKitRuntime.systemFontCut == .iOS, let sv = _scrollView {
            // Stretch the large-title bar FIRST (adj 116 → 176). The
            // scroll view's safe-area rebase then pins offset to the NEW
            // top (−176). Subtract the control height AFTER that, or the
            // rebase eats it (Feed t700: offset −176 → −236).
            // The −0.5 slack is so a rest offset of 0 with adj 0 (suite
            // control_refresh) is NOT treated as overscroll — `y < 0.5`
            // would have been true and subtracted 60 (golden frame.y 0).
            let overscrolled = sv.contentOffset.y < -sv.adjustedContentInset.top - 0.5
            sv._scrollObserver?.scrollViewDidScroll(sv)
            sv.layoutIfNeeded()
            if overscrolled {
                sv.contentOffset.y -= UIRefreshControl.controlHeight
            }
        }
        setNeedsDisplay()
    }

    /// Stops the spinner and gives back any inset this control was holding.
    public func endRefreshing() {
        guard isRefreshing else { return }
        isRefreshing = false
        isHidden = true
        _armed = false
        setNeedsDisplay()
        if OpenUIKitRuntime.systemFontCut == .iOS, let sv = _scrollView {
            // Shrink the stretched large-title bar (Feed t1800 returns to
            // bar [0, 10, 375, 106], adj 116).
            sv._scrollObserver?.scrollViewDidScroll(sv)
        }
        guard _holdsInset, let sv = _scrollView else { return }
        _holdsInset = false
        let restored = _baseTopInset
        let wasAtTop = sv.contentOffset.y <= -sv.contentInset.top + 0.5
        sv.contentInset.top = restored
        if wasAtTop { sv.contentOffset.y = -restored }
        sv.setNeedsLayout()
    }

    /// Hold the scroll view open at the control's height (documented UIKit
    /// behaviour for a user-started refresh; NOT measured — file header).
    private func _holdInsetOpen() {
        guard !_holdsInset, let sv = _scrollView else { return }
        _holdsInset = true
        _baseTopInset = sv.contentInset.top
        sv.contentInset.top = _baseTopInset + UIRefreshControl.controlHeight
        if sv.contentOffset.y <= -_baseTopInset {
            sv.contentOffset.y = -sv.contentInset.top
        }
        sv.setNeedsLayout()
    }

    // MARK: Scroll-view driven state (see the file header for what is and is
    // not measured)

    /// Called by the scroll view on every offset change while dragging.
    func _scrollDidDrag(to offsetY: CGFloat, topEdge: CGFloat) {
        guard !isRefreshing else { return }
        let pulled = topEdge - offsetY
        isHidden = pulled <= 0
        if pulled >= UIRefreshControl.controlHeight { _armed = true }
        setNeedsDisplay()
    }

    /// Called by the scroll view when the drag ends.
    func _scrollDidEndDrag() {
        guard !isRefreshing else { return }
        guard _armed else { isHidden = true; return }
        _armed = false
        beginRefreshing()
        _holdInsetOpen()
        sendActions(for: .valueChanged)
    }

    // MARK: Drawing

    /// Ease-in-out cubic bezier (0.42, 0, 0.58, 1) — UIView's default
    /// timing and the measured replicator opacity curve.
    /// spinnerprobe rc_n0..24, iPhone SE 2x / iOS 26.1: popacity(t)
    /// for t = n/60 of a 1 s animation, rms 3e-7.
    static func easeInOut(_ t: CGFloat) -> CGFloat {
        if t <= 0 { return 0 }
        if t >= 1 { return 1 }
        let c1x: CGFloat = 0.42, c1y: CGFloat = 0
        let c2x: CGFloat = 0.58, c2y: CGFloat = 1
        var lo: CGFloat = 0, hi: CGFloat = 1
        for _ in 0..<48 {
            let s = (lo + hi) / 2
            let om = 1 - s
            let xv = 3 * om * om * s * c1x + 3 * om * s * s * c2x + s * s * s
            if xv < t { lo = s } else { hi = s }
        }
        let s = (lo + hi) / 2
        let om = 1 - s
        return 3 * om * om * s * c1y + 3 * om * s * s * c2y + s * s * s
    }

    /// Seconds since `beginRefreshing`, clamped at 0. Named conformance
    /// frames: Feed t700 = 0.30, Pager t4650 = 0.15.
    var appearElapsed: Double {
        max(0, OpenUIKitRuntime.animationTime - animationStart)
    }

    public override func drawContent(in canvas: Canvas, bounds: CGRect) {
        guard bounds.width > 0, bounds.height > 0 else { return }
        // Measured: `rc.tintColor` is nil on a fresh control even inside a
        // scroll view. Catalyst rest / frozen SimScene seed is `label` at
        // 216/255. iOS 26.1 appear (elapsed > 0) seed is `secondaryLabel`
        // (spinnerprobe rc_n9/n18 pbg; Feed t700 / Pager t4650). An
        // explicit tint still wins.
        let elapsed = appearElapsed
        let iOSAppear = OpenUIKitRuntime.systemFontCut == .iOS
            && isRefreshing && elapsed > 0
        if iOSAppear {
            OpenUIKitRuntime.noteAnimationWork(
                until: OpenUIKitRuntime.animationTime + 1.0 / 60.0)
        }
        let defaultColor: UIColor = iOSAppear ? .secondaryLabel : .label
        let base = (_tintColor ?? defaultColor).resolvedCGColor(with: traitCollection)
        guard base.alpha > 0 else { return }
        let fade: CGFloat
        let extraPhi: CGFloat
        if iOSAppear {
            let u = min(1.0, elapsed / UIRefreshControl.iOSAppearOpacityDuration)
            fade = UIRefreshControl.easeInOut(CGFloat(u))
            let step = Int((elapsed / UIRefreshControl.iOSAppearStepDuration)
                .rounded(.down)) % UIRefreshControl.bladeCount
            extraPhi = CGFloat(step) * .pi / 4
        } else {
            fade = UIRefreshControl.bladeAlpha
            extraPhi = 0
        }
        let color = base.withAlpha(base.alpha * fade)
        let cx = bounds.midX
        let cy = bounds.midY
        // The SEED blade, in the graphic's own coordinates. Measured frame is
        // (48.5, 35, 3.5, 10) inside the 100x100 replicator box, so the blade
        // is axis-aligned, points UP, and its centre is (50.25, 40) — a
        // quarter point RIGHT of the box centre (50, 50) and 10 pt above it.
        // That 0.25 pt is not noise: without it every diagonal blade lands
        // half a point off the golden.
        let seed = CGRect(x: cx + UIRefreshControl.bladeSeedDX
                             - UIRefreshControl.bladeThickness / 2,
                          y: cy - UIRefreshControl.bladeRing
                             - UIRefreshControl.bladeLength / 2,
                          width: UIRefreshControl.bladeThickness,
                          height: UIRefreshControl.bladeLength)
        let capsule = Path.roundedRect(seed,
                                       cornerRadius: UIRefreshControl.bladeThickness / 2)
        for k in 0..<UIRefreshControl.bladeCount {
            // The replicator rotates each instance a further 45 degrees about
            // the graphic centre (measured instanceTransform). iOS appear
            // adds the discrete 45° step of the whole ring.
            let phi = CGFloat(k) * .pi / 4 + extraPhi
            let t = CGAffineTransform(translationX: -cx, y: -cy)
                .concatenating(CGAffineTransform(rotationAngle: phi))
                .concatenating(CGAffineTransform(translationX: cx, y: cy))
            canvas.fill(capsule.applying(t), color: color)
        }
    }
}

// MARK: - UIScrollView integration

extension UIScrollView {
    /// The pull-to-refresh control. Assigning one installs it as the scroll
    /// view's FIRST subview, which is where real UIKit puts it (measured:
    /// `subviews == [UIRefreshControl, _UIScrollerImpContainerView, …]`).
    public var refreshControl: UIRefreshControl? {
        get { _refreshControl }
        set {
            guard _refreshControl !== newValue else { return }
            if let old = _refreshControl {
                old.removeFromSuperview()
                old._scrollView = nil
            }
            _refreshControl = newValue
            guard let rc = newValue else { return }
            rc._scrollView = self
            insertSubview(rc, at: 0)
            setNeedsLayout()
        }
    }

    /// Measured Catalyst: frame = (0, contentOffset.y, width, 60).
    /// MEASURED iOS 26.1, Feed t200/t700/t2800, iPhone SE 2x: the modern
    /// refresh control's window abs.y is 64 at every offset (−116, −236,
    /// 352), i.e. `frame.y = contentOffset.y + 64` whenever the scroll view
    /// is under a navigation overlay (`adjustedContentInset.top >= 64`).
    /// A scroll view with no nav overlay (adj 0, fixture control_refresh)
    /// keeps the Catalyst origin.
    func _layoutRefreshControl() {
        guard let rc = _refreshControl else { return }
        var y = contentOffset.y
        if OpenUIKitRuntime.systemFontCut == .iOS,
           adjustedContentInset.top >= UINavigationBar.barHeight - 0.5 {
            y += UINavigationBar.barHeight
        }
        rc.frame = CGRect(x: 0, y: y, width: bounds.width,
                          height: UIRefreshControl.controlHeight)
    }

    /// The offset at which the content's top edge is flush with the top of
    /// the scroll view — `-contentInset.top`, minus the inset the refresh
    /// control itself is holding open while it spins.
    var _refreshTopEdge: CGFloat {
        guard let rc = _refreshControl, rc._holdsInset else { return -contentInset.top }
        return -rc._baseTopInset
    }
}

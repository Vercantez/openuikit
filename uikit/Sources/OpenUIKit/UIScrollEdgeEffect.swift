// UIScrollEdgeEffect — iOS 26's per-edge effect object on UIScrollView
// (`topEdgeEffect` / `bottomEdgeEffect` / `leftEdgeEffect` /
// `rightEdgeEffect`, each with `style` and `isHidden`). Owner: scroll module.
//
// MEASURED 2026-09-10, Tools/oracle2/scrolledgeeffectprobe (iPhone 16 /
// iOS 26.1, ios-26.1-iphone16.json + profiles-ios-26.1-iphone16.json,
// report docs/agent_reports/scroll-edge-effect.md):
//
//   STATE   `UIScrollEdgeEffect` and `UIScrollEdgeEffectStyle` are NSObject
//           subclasses; the three styles are process-wide singletons
//           (identity-equal, `isEqual` identity). A scroll view holds FOUR
//           distinct, stable effect objects, never shared with another
//           scroll view. Defaults: `.automatic`, `isHidden == false`, on a
//           plain UIScrollView, a UITableView and a UICollectionView alike,
//           attached or not, under a navigation bar, a tab bar or a toolbar.
//           Setting `style` / `isHidden` reads back as set.
//   TREE    Apple's painter lives IN THE SCROLL VIEW: two
//           `_UITouchPassthroughView`s pinned to the visible rect hold one
//           `ScrollEdgeEffectView` per engaged edge. A container interaction
//           (UIScrollEdgeElementContainerInteraction) does not add a second
//           painter: the same top effect view grows to cover the container
//           (247.8 tall for a 113 pt bar + 100 pt container). One object,
//           one painter per edge.
//   ENGAGE  Under a navigation bar (bar frame [0, 59, 393, 54], safe top 113)
//           the top effect is OFF through 8 pt of content under the safe
//           edge and ON at 12: the trigger is the bar's glass edge at 103
//           (= safe top − 10), not the safe area. Under a tab bar (frame
//           [0, 769, 393, 83] == safe bottom) the bottom effect is ON at 1 pt.
//           At the top rest the bottom effect is already on when content
//           runs past the tab bar. A large-title bar shows nothing until it
//           collapses (12 and 40 pt: raw content).
//   HIDDEN  `isHidden = true` sets the effect view's alpha to 0: raw content
//           through the bar zone (rows 0–12 white, then the bands), the
//           navigation bar itself untouched. It also removes the band a
//           container interaction produces (interaction.topHidden: raw).
//   HARD    `ScrollEdgeEffectView` becomes [0, 0, 393, 103] (top, = bar
//           frame maxY 113 − 10) / [0, 769, 393, 83] (tab bar frame) /
//           [0, 776, 393, 76] (toolbar: safe bottom 86 − 10) / [0, 0, 393,
//           183] (container: inner edge 213 − 30); PocketMask hidden,
//           gaussianBlur, BackdropView α 0.90. Pixels at x 380: a flat WHITE
//           plate, red (255,0,0) reads (255,230,230), black reads
//           (230,230,230) — α 0.902 — with a ~6 pt blur at band boundaries,
//           and a HARD CUT at the plate edge (row 103 raw). No dividing line
//           visible on red at rows 103 / 183 / 776.
//   SOFT    `.soft`, and `.automatic` once any style was assigned, is a
//           white wash without the dark zone: black reads 213 (α 0.835)
//           flat through row 57, easing to 0 at row 149 (safe top + 36);
//           bottom: 0 at row 730 rising to 0.78 at 830. Recorded, not
//           painted (needs the variable blur; docs/KNOWN_GAPS.md).
//   AUTO    The untouched `.automatic` material under an inline bar is
//           luminance-adaptive and was not stable between two visits of the
//           same offset (mid vs mid2 differ on 110 rows). Recorded only; the
//           port keeps painting nothing under an inline bar, the large-title
//           pocket in UINavigationBar, the dark tab-bar gradient in UITabBar,
//           and the Signal-order black scrim for a container.
//   LEFT/RIGHT  Store-only (defaults measured, no horizontal content probed).
//
// What the port routes through the effect: the container interaction's
// pocket (hidden → gone; `.hard` → the plate from the visible edge to the
// container's inner edge − 30), the navigation bar's large-title pocket and
// the tab bar's bottom gradient (hidden or `.hard` → not painted), and a new
// scroll-view-owned plate under a navigation bar / toolbar / tab bar for
// `.hard` (`_UIScrollEdgeEffectView`, the measured geometry above).

#if canImport(Foundation)
import class Foundation.NSObject
import class Foundation.NSCoder
#elseif canImport(ObjectiveC)
import class ObjectiveC.NSObject
#else
#error("UIScrollEdgeEffect requires NSObject")
#endif

@preconcurrency @MainActor
public final class UIScrollEdgeEffect: NSObject {
    /// Styles for a scroll view's edge effect (`UIScrollEdgeEffectStyle`).
    /// Three singletons; identity is equality (measured).
    @preconcurrency @MainActor
    public final class Style: NSObject {
        let name: String
        private init(name: String) { self.name = name }

        /// The automatic scroll edge effect style.
        public static let automatic = Style(name: "automatic")
        /// A soft-edged scroll edge effect.
        public static let soft = Style(name: "soft")
        /// A scroll edge effect with a hard cutoff and dividing line.
        public static let hard = Style(name: "hard")

        nonisolated public override var description: String { "<UIScrollEdgeEffectStyle: \(name)>" }
    }

    /// The edge this effect describes (one of `.top/.left/.bottom/.right`).
    public let edge: UIRectEdge
    weak var scrollView: UIScrollView?

    init(edge: UIRectEdge, scrollView: UIScrollView) {
        self.edge = edge
        self.scrollView = scrollView
    }

    /// The style of this edge effect. Default `.automatic`.
    public var style: Style = .automatic {
        didSet { if style !== oldValue { scrollView?._edgeEffectDidChange(self) } }
    }

    /// Whether this edge effect is hidden. Default `false`.
    public var isHidden: Bool = false {
        didSet { if isHidden != oldValue { scrollView?._edgeEffectDidChange(self) } }
    }

    /// True when nothing should be painted for this edge (measured: alpha 0
    /// on the effect view).
    var paintsNothing: Bool { isHidden }

    /// True when the edge paints the measured hard plate instead of the
    /// automatic material.
    var isHard: Bool { !isHidden && style === Style.hard }

    /// Alpha of the white hard plate over the content: red (255,0,0) reads
    /// (255,230,230), black reads (230,230,230) → 230/255.
    static let hardPlateAlpha: CGFloat = 230.0 / 255.0

    /// The hard plate's inner edge sits 10 pt inside a navigation bar's or
    /// toolbar's safe-area edge (the glass gap) and 30 pt inside a container
    /// interaction's inner edge; a tab bar's plate is the bar frame.
    static let barGlassGap: CGFloat = 10
    static let containerHardInset: CGFloat = 30

    /// Penetration (content past the plate edge) that engages a bar's
    /// effect: off at 8 pt under the safe edge (= −2 past the glass edge),
    /// on at 12 (= +2); the tab bar is on at 1.
    static let engagementThreshold: CGFloat = 0.5
}

/// The scroll-view-owned plate for `.hard` under a bar: Apple's
/// `ScrollEdgeEffectView` in its `_UITouchPassthroughView`, pinned to the
/// visible rect. Only exists while an edge is `.hard`, shown, and content
/// passes under the bar's glass edge.
@preconcurrency @MainActor
final class _UIScrollEdgeEffectView: UIView {
    let edge: UIRectEdge

    init(edge: UIRectEdge) {
        self.edge = edge
        super.init(frame: .zero)
        isUserInteractionEnabled = false
        isOpaque = false
        backgroundColor = nil
        accessibilityIdentifier = "ScrollEdgeEffectView"
    }

    required init?(coder: NSCoder) {
        edge = .top
        super.init(coder: coder)
    }

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? { nil }

    override func drawContent(in canvas: Canvas, bounds: CGRect) {
        guard bounds.width > 0, bounds.height > 0 else { return }
        canvas.fill(rect: bounds, color: UIScrollEdgeEffect.hardPlateColor(for: traitCollection))
    }
}

extension UIScrollEdgeEffect {
    /// MEASURED light only (white 230 over both red and black). Dark is
    /// unmeasured: the plate follows the system background there.
    static func hardPlateColor(for traits: UITraitCollection) -> CGColor {
        UIColor.systemBackground.resolvedCGColor(with: traits).withAlpha(hardPlateAlpha)
    }
}

extension UIView {
    /// The nearest view controller up the responder chain (the controller
    /// whose root view this is, or an ancestor's).
    var _nearestViewController: UIViewController? {
        var r: UIResponder? = next
        while let cur = r {
            if let vc = cur as? UIViewController { return vc }
            r = cur.next
        }
        return nil
    }
}

extension UIViewController {
    /// The scroll view a bar's edge effect follows: the explicit
    /// `setContentScrollView(_:)` binding, else the visible leaf
    /// controller's root scroll view, else its first direct scroll-view
    /// subview reaching `edge`.
    func _resolvedContentScrollView(for edge: UIRectEdge) -> UIScrollView? {
        if let s = _contentScrollView { return s }
        if let nav = self as? UINavigationController {
            return nav.topViewController?._resolvedContentScrollView(for: edge)
        }
        if let tab = self as? UITabBarController {
            return tab.selectedViewController?._resolvedContentScrollView(for: edge)
        }
        guard let v = viewIfLoaded else { return nil }
        if let s = v as? UIScrollView { return s }
        return v.subviews.compactMap { $0 as? UIScrollView }.first { s in
            edge == .bottom ? s.frame.maxY >= v.bounds.maxY - 0.5
                            : s.frame.minY <= v.bounds.minY + 0.5
        }
    }
}

extension UIScrollView {
    /// The effect object for an edge without creating it: an untouched
    /// scroll view has no effect objects and paints as before.
    func _edgeEffectIfPresent(_ edge: UIRectEdge) -> UIScrollEdgeEffect? {
        switch edge {
        case .top: return _topEdgeEffect
        case .bottom: return _bottomEdgeEffect
        case .left: return _leftEdgeEffect
        case .right: return _rightEdgeEffect
        default: return nil
        }
    }

    /// True when a bar painter for `edge` (large-title pocket, tab-bar
    /// gradient, container scrim) must stay off: the effect is hidden, or
    /// `.hard` replaces it with the plate.
    func _edgeEffectSuppressesAutomaticPainter(_ edge: UIRectEdge) -> Bool {
        guard let e = _edgeEffectIfPresent(edge) else { return false }
        return e.paintsNothing || e.isHard
    }

    /// A style or hidden flag changed: re-evaluate our pockets now and ask
    /// the bars that paint for this scroll view to re-layout.
    func _edgeEffectDidChange(_ effect: UIScrollEdgeEffect) {
        _updateScrollEdgeEffects()
        _updateScrollEdgeInteractions()
        if let vc = _nearestViewController {
            vc.navigationController?.navigationBar.setNeedsLayout()
            vc.navigationController?.navigationBar.updatePocket()
            vc.tabBarController?.tabBar.setNeedsLayout()
            vc.tabBarController?.tabBar.layoutBottomEdgeEffect()
        }
        setNeedsLayout()
    }

    /// Distance from the visible `edge` to the hard plate's inner edge, from
    /// the bars this scroll view sits under (measured: navigation bar frame
    /// maxY − 10; toolbar slot top + 10; tab bar frame). Nil without a bar.
    func _barPlateExtent(for edge: UIRectEdge) -> CGFloat? {
        guard let vc = _nearestViewController else { return nil }
        var extent: CGFloat?
        func consider(_ bar: UIView, gap: CGFloat) {
            guard !bar.isHidden, bar.window != nil, bar.bounds.width > 0 else { return }
            // A bar counts for the edge it sits at (the navigation bar
            // starts below the status bar; the plate still starts at the
            // visible edge, measured [0, 0, 393, 103]).
            let r = bar.convert(bar.bounds, to: self)
            let e: CGFloat
            if edge == .top {
                guard r.midY < bounds.midY else { return }
                e = r.maxY - gap - bounds.minY
            } else {
                guard r.midY > bounds.midY else { return }
                e = bounds.maxY - (r.minY + gap)
            }
            guard e > 0 else { return }
            extent = max(extent ?? 0, e)
        }
        let ios = OpenUIKitRuntime.systemFontCut == .iOS
        if let nav = vc.navigationController {
            if edge == .top, !nav.isNavigationBarHidden {
                consider(nav.navigationBar, gap: ios ? UIScrollEdgeEffect.barGlassGap : 0)
            }
            if edge == .bottom, !nav.isToolbarHidden, nav.toolbarHeight > 0 {
                consider(nav.toolbar, gap: ios ? _UIBarMetrics.toolbarSlotTopPadding : 0)
            }
        }
        if edge == .bottom, let tab = vc.tabBarController, !UITabBar.isPad {
            consider(tab.tabBar, gap: 0)
        }
        return extent
    }

    /// Every scroll step and layout pass: the hard plate under a bar exists
    /// while the edge is `.hard`, shown, no container interaction paints the
    /// edge (one painter per edge, measured), and content passes under the
    /// bar's glass edge.
    func _updateScrollEdgeEffects() {
        for edge in [UIRectEdge.top, .bottom] {
            let existing = edge == .top ? _topEdgePocket : _bottomEdgePocket
            guard let effect = _edgeEffectIfPresent(edge), effect.isHard,
                  !_scrollEdgeInteractions.contains(where: { ref in
                      ref.interaction.map { $0.edge == edge && $0.view != nil } ?? false }),
                  let extent = _barPlateExtent(for: edge) else {
                existing?.isHidden = true
                continue
            }
            let engaged = edge == .top
                ? bounds.minY + extent > UIScrollEdgeEffect.engagementThreshold
                : contentSize.height - (bounds.maxY - extent) > UIScrollEdgeEffect.engagementThreshold
            guard engaged else {
                existing?.isHidden = true
                continue
            }
            let pocket: _UIScrollEdgeEffectView
            if let existing, existing.superview === self {
                pocket = existing
            } else {
                existing?.removeFromSuperview()
                pocket = _UIScrollEdgeEffectView(edge: edge)
                addSubview(pocket)
                if edge == .top { _topEdgePocket = pocket } else { _bottomEdgePocket = pocket }
            }
            let frame = edge == .top
                ? CGRect(x: bounds.minX, y: bounds.minY, width: bounds.width, height: extent)
                : CGRect(x: bounds.minX, y: bounds.maxY - extent, width: bounds.width, height: extent)
            if pocket.frame != frame {
                pocket.frame = frame
                pocket.setNeedsDisplay()
            }
            pocket.isHidden = false
            bringSubviewToFront(pocket)
            _frontIndicatorsOverPockets()
        }
    }
}
